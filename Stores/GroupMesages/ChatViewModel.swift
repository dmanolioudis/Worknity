//
//  ChatViewModel.swift
//  Worknity
//
//  Created by Dee Manolioudis on 8/7/26.
//

// ChatViewModel.swift
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import AVFoundation

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var sendingMessages: [ChatMessage] = [] // Μηνύματα σε κατάσταση αποστολής
    @Published var lastReadMessageForUser: [String: String] = [:]
    @Published var userProfileImages: [String: String] = [:]
    @Published var userNames: [String: String] = [:]
    @Published var isUploading = false
    @Published var operationError: String?
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    let storeID: String
    let groupID: String?
    private var messagesListener: ListenerRegistration?
    private var hasConversationAccess = false
    private var listenerGeneration = UUID()
    private var messagesCollection: CollectionReference {
        let store = db.collection("stores").document(storeID)
        if let groupID { return store.collection("groups").document(groupID).collection("messages") }
        return store.collection("messages")
    }

    init(storeID: String, groupID: String? = nil, startListening: Bool = true) {
        self.storeID = storeID
        self.groupID = groupID
        if startListening { fetchMessages() }
    }
    
    deinit { messagesListener?.remove() }

    func stopListening() {
        hasConversationAccess = false
        listenerGeneration = UUID()
        messagesListener?.remove()
        messagesListener = nil
        messages = []
        sendingMessages = []
    }

    func fetchMessages() {
        guard messagesListener == nil else { return }
        hasConversationAccess = true
        let generation = UUID()
        listenerGeneration = generation
        messagesListener = messagesCollection
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, self.hasConversationAccess, self.listenerGeneration == generation else { return }
                self.operationError = error?.localizedDescription
                self.messages = snapshot?.documents.compactMap { try? $0.data(as: ChatMessage.self) } ?? []
                self.calculateLastReadMessages()
                self.fetchUsersData()
            }
    }
    
    func sendMessage(text: String) {
        guard hasConversationAccess, let user = Auth.auth().currentUser else { return }
        
        // ΔΙΟΡΘΩΣΗ: Το reactions μπήκε πριν το readBy και προστέθηκαν ρητά τα media ως nil
        let msg = ChatMessage(
            senderID: user.uid,
            senderName: userNames[user.uid] ?? "Χρήστης",
            text: text,
            timestamp: Date(),
            mediaURL: nil,
            mediaType: nil,
            thumbnailURL: nil,
            reactions: [:],
            readBy: [user.uid]
        )
        do {
            try messagesCollection.addDocument(from: msg) { [weak self] error in
                DispatchQueue.main.async { self?.operationError = error?.localizedDescription }
            }
        } catch { operationError = error.localizedDescription }
    }

    // Helper: Δημιουργία τοπικού thumbnail από το αρχείο βίντεο στη συσκευή
    private func generateLocalThumbnail(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.0, preferredTimescale: 60)
        if let imageRef = try? generator.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: imageRef)
        }
        return nil
    }
    
    func sendMediaMessage(item: ChatMediaItem, caption: String) {
        guard hasConversationAccess, let user = Auth.auth().currentUser else { return }
        
        let fileID = UUID().uuidString
        let finalCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (caseImage(item) ? "🖼️ Φωτογραφία" : "🎥 Βίντεο") : caption
        
        // 🚀 ΒΗΜΑ 1: Μεταφέρουμε τη βαριά επεξεργασία σε Background Thread για να μην κολλάει το UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var localImg: UIImage? = nil
            var mediaTypeString = ""
            
            switch item {
            case .image(let data):
                localImg = UIImage(data: data)
                mediaTypeString = "image"
            case .video(let localURL):
                // Εδώ γινόταν η καθυστέρηση, τώρα τρέχει στο παρασκήνιο!
                localImg = self.generateLocalThumbnail(url: localURL)
                mediaTypeString = "video"
            }
            
            let tempID = UUID().uuidString
            
            let tempMessage = ChatMessage(
                id: tempID,
                senderID: user.uid,
                senderName: self.userNames[user.uid] ?? "Χρήστης",
                text: finalCaption,
                timestamp: Date(),
                mediaURL: nil,
                mediaType: mediaTypeString,
                thumbnailURL: nil,
                reactions: [:],
                readBy: [user.uid],
                isSending: true,
                localImage: localImg
            )
            
            // 🔄 ΒΗΜΑ 2: Επιστρέφουμε στον Main Thread ΜΟΝΟ για να δείξουμε το μήνυμα στην οθόνη
            DispatchQueue.main.async {
                self.sendingMessages.append(tempMessage)
            }
            
            // 💾 ΒΗΜΑ 3: Ανέβασμα στο Firebase (εκτελείται ήδη ασύγχρονα από το SDK)
            let ref = self.storage.reference().child("stores/\(self.storeID)/chat_media/\(fileID)")
            let metadata = StorageMetadata()
            
            switch item {
            case .image(let data):
                metadata.contentType = "image/jpeg"
                ref.putData(data, metadata: metadata) { _, _ in
                    ref.downloadURL { url, _ in
                        self.saveMediaMessageToFirestore(mediaURL: url?.absoluteString, thumbnailURL: nil, type: "image", text: finalCaption, user: user, tempID: tempID)
                    }
                }
            case .video(let localURL):
                metadata.contentType = "video/mp4"
                ref.putFile(from: localURL, metadata: metadata) { _, _ in
                    ref.downloadURL { videoURL, _ in
                        
                        if let localImg = localImg, let thumbData = localImg.jpegData(compressionQuality: 0.6) {
                            let thumbRef = self.storage.reference().child("stores/\(self.storeID)/chat_media/\(fileID)_thumb.jpg")
                            let thumbMeta = StorageMetadata()
                            thumbMeta.contentType = "image/jpeg"
                            
                            thumbRef.putData(thumbData, metadata: thumbMeta) { _, _ in
                                thumbRef.downloadURL { thumbURL, _ in
                                    self.saveMediaMessageToFirestore(mediaURL: videoURL?.absoluteString, thumbnailURL: thumbURL?.absoluteString, type: "video", text: finalCaption, user: user, tempID: tempID)
                                    try? FileManager.default.removeItem(at: localURL)
                                }
                            }
                        } else {
                            self.saveMediaMessageToFirestore(mediaURL: videoURL?.absoluteString, thumbnailURL: nil, type: "video", text: finalCaption, user: user, tempID: tempID)
                            try? FileManager.default.removeItem(at: localURL)
                        }
                    }
                }
            }
        }
    }
    
    private func saveMediaMessageToFirestore(mediaURL: String?, thumbnailURL: String?, type: String, text: String, user: User, tempID: String) {
        guard let mediaURL = mediaURL else {
            DispatchQueue.main.async { self.sendingMessages.removeAll { $0.id == tempID } }
            return
        }
        
        // Σωστή σειρά παραμέτρων Firestore εγγραφής
        let msg = ChatMessage(
            senderID: user.uid,
            senderName: self.userNames[user.uid] ?? "Χρήστης",
            text: text,
            timestamp: Date(),
            mediaURL: mediaURL,
            mediaType: type,
            thumbnailURL: thumbnailURL,
            reactions: [:],
            readBy: [user.uid]
        )
        
        try? self.messagesCollection.addDocument(from: msg) { error in
            DispatchQueue.main.async {
                self.operationError = error?.localizedDescription
                self.sendingMessages.removeAll { $0.id == tempID }
            }
        }
    }
    
    func markMessageAsRead(message: ChatMessage) { guard hasConversationAccess, let userID = Auth.auth().currentUser?.uid, let messageID = message.id else { return } ; if let readBy = message.readBy, readBy.contains(userID) { return } ; messagesCollection.document(messageID).updateData(["readBy": FieldValue.arrayUnion([userID])]) }
    
    
    func handleReaction(message: ChatMessage, emoji: String) { guard hasConversationAccess, let userID = Auth.auth().currentUser?.uid, let messageID = message.id else { return } ; var currentReactions = message.reactions ?? [:] ; if currentReactions[userID] == emoji { currentReactions.removeValue(forKey: userID) } else { currentReactions[userID] = emoji } ; messagesCollection.document(messageID).updateData(["reactions": currentReactions]) }
    
    
    func deleteMessage(messageID: String) { guard hasConversationAccess else { return }; messagesCollection.document(messageID).delete() }
    
    
    func editMessage(messageID: String, newText: String) { guard hasConversationAccess else { return }; messagesCollection.document(messageID).updateData(["text": newText]) }
    
    
    private func calculateLastReadMessages() { var tempLastRead: [String: String] = [:] ; for message in messages { guard let id = message.id, let readBy = message.readBy else { continue } ; for userID in readBy { tempLastRead[userID] = id } } ; DispatchQueue.main.async { self.lastReadMessageForUser = tempLastRead } }
    private func fetchUsersData() { var allUserIDs = Set<String>() ; for message in messages { allUserIDs.insert(message.senderID) ; if let readBy = message.readBy { allUserIDs.formUnion(readBy) } } ; for userID in allUserIDs { if userProfileImages[userID] == nil || userNames[userID] == nil { db.collection("users").document(userID).getDocument { doc, _ in if let data = doc?.data() { let fullName = data["fullName"] as? String ?? "Χρήστης" ; let photoURL = data["photoURL"] as? String ?? "" ; DispatchQueue.main.async { self.userNames[userID] = fullName ; self.userProfileImages[userID] = photoURL } } } } } }
    private func caseImage(_ item: ChatMediaItem) -> Bool { if case .image = item { return true } ; return false }
}
