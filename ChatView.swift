//
//  ChatView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 8/7/26.
//

// ChatView.swift
import SwiftUI
import FirebaseAuth
import AVKit

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @Binding var tabBarMode: TabBarMode
    
    @State private var messageText = ""
    @State private var selectedMessageID: String? = nil
    @State private var editingMessageID: String? = nil
    @State private var isEditingMode = false
    @State private var showMediaPicker = false
    @State private var fullscreenMediaMessage: ChatMessage? = nil
    @State private var selectedMediaItem: ChatMediaItem? = nil
    
    var body: some View {
        // Συνδυασμός κανονικών μηνυμάτων και αυτών που αποστέλλονται αυτή τη στιγμή
        let allMessages = viewModel.messages + viewModel.sendingMessages
        
        VStack(spacing: 0) {
            // MARK: - Μηνύματα Συνομιλίας
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 6) {
                        ForEach(Array(allMessages.enumerated()), id: \.element.id) { item in
                            let index = item.offset
                            let message = item.element
                            
                            let isFirstInBlock = index == 0 || allMessages[index - 1].senderID != message.senderID
                            let isMe = message.senderID == Auth.auth().currentUser?.uid
                            let isSending = message.isSending ?? false // Έλεγχος αν στέλνεται τώρα
                            
                            let readersOfThisMessage = viewModel.lastReadMessageForUser
                                .filter { $0.value == message.id }
                                .map { $0.key }
                            
                            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                                
                                // Header Αλλαγής Συνομιλητή
                                if isFirstInBlock && !isMe {
                                    HStack(spacing: 8) {
                                        UserProfileImageView(urlString: viewModel.userProfileImages[message.senderID], size: 24)
                                        Text(viewModel.userNames[message.senderID] ?? message.senderName)
                                            .font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.top, 10).padding(.leading, 4)
                                }
                                
                                // Κύριο Σώμα Μηνύματος
                                HStack(spacing: 8) {
                                    if isMe {
                                        Spacer()
                                        // ΝΕΟ: Ένδειξη δίπλα από το μήνυμα ότι γίνεται αποστολή
                                        if isSending {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.secondary)
                                        }
                                    }
                                    
                                    VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                                        ZStack(alignment: .bottomTrailing) {
                                            
                                            // Απεικόνιση Media
                                            if isSending, let localImg = message.localImage {
                                                // Ακαριαίο Optimistic UI χρησιμοποιώντας τη RAM της συσκευής
                                                Image(uiImage: localImg)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 220, height: message.mediaType == "image" ? 220 : 150)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        Group {
                                                            if message.mediaType == "video" {
                                                                Image(systemName: "play.circle.fill")
                                                                    .font(.system(size: 45)).foregroundColor(.white.opacity(0.85))
                                                            }
                                                        }
                                                    )
                                            } else if let mediaURL = message.mediaURL, let mediaType = message.mediaType {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    if mediaType == "image" {
                                                        AsyncImage(url: URL(string: mediaURL)) { img in
                                                            img.resizable().scaledToFill()
                                                        } placeholder: {
                                                            ProgressView().frame(width: 220, height: 220)
                                                        }
                                                        .frame(width: 220, height: 220)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    } else if mediaType == "video" {
                                                        // ΝΕΟ: Φόρτωση του έτοιμου Thumbnail από το cloud (Σφαίρα!)
                                                        if let thumbURL = message.thumbnailURL, let url = URL(string: thumbURL) {
                                                            AsyncImage(url: URL(string: thumbURL)) { img in
                                                                img.resizable().scaledToFill()
                                                            } placeholder: {
                                                                ProgressView().frame(width: 220, height: 150)
                                                            }
                                                            .frame(width: 220, height: 150)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                            .overlay(Image(systemName: "play.circle.fill").font(.system(size: 45)).foregroundColor(.white.opacity(0.85)))
                                                        } else if let url = URL(string: mediaURL) {
                                                            // Fallback για παλιά βίντεο χωρίς thumbnailURL
                                                            VideoThumbnailView(videoURL: url)
                                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                        }
                                                    }
                                                    
                                                    // Λεζάντα
                                                    if message.text != "🖼️ Φωτογραφία" && message.text != "🎥 Βίντεο" {
                                                        Text(message.text)
                                                            .font(.system(size: 15))
                                                            .padding(.horizontal, 4).padding(.bottom, 4)
                                                    }
                                                }
                                                .padding(6)
                                                .background(isMe ? Color(hex: "#948979") : Color.gray.opacity(0.2))
                                                .foregroundColor(isMe ? .white : .primary)
                                                .cornerRadius(14)
                                                .onTapGesture { if !isSending { fullscreenMediaMessage = message } }
                                            } else {
                                                // Μήνυμα Κειμένου
                                                Text(message.text)
                                                    .padding(10)
                                                    .background(isMe ? Color(hex: "#948979") : Color.gray.opacity(0.2))
                                                    .foregroundColor(isMe ? .white : .primary)
                                                    .cornerRadius(12)
                                                    .onTapGesture {
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                            selectedMessageID = (selectedMessageID == message.id) ? nil : message.id
                                                        }
                                                    }
                                            }
                                            
                                            // Reactions Badge
                                            if let reactions = message.reactions, !reactions.isEmpty {
                                                let uniqueEmojis = Array(Set(reactions.values)).prefix(3)
                                                HStack(spacing: 2) {
                                                    ForEach(uniqueEmojis, id: \.self) { emoji in Text(emoji).font(.system(size: 11)) }
                                                    if reactions.count > 1 { Text("\(reactions.count)").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary) }
                                                }
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Color(.systemBackground)).clipShape(Capsule())
                                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                                                .offset(x: isMe ? -8 : 8, y: 8).zIndex(2)
                                            }
                                        }
                                        
                                        if selectedMessageID == message.id {
                                            Text(formatTime(message.timestamp)).font(.system(size: 11, weight: .medium)).foregroundColor(.secondary).padding(.horizontal, 6)
                                                .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                    }
                                    .id(message.id)
                                    .contextMenu {
                                        if !isSending {
                                            Menu("Προσθήκη Αντίδρασης... 🎭") {
                                                Button("❤️ Καρδιά") { viewModel.handleReaction(message: message, emoji: "❤️") }
                                                Button("👍 Μου αρέσει") { viewModel.handleReaction(message: message, emoji: "👍") }
                                                Button("👎 Δεν μου αρέσει") { viewModel.handleReaction(message: message, emoji: "👎") }
                                            }
                                            if isMe {
                                                Divider()
                                                if message.mediaURL == nil {
                                                    Button(action: { editingMessageID = message.id; messageText = message.text; isEditingMode = true }) { Label("Επεξεργασία", systemImage: "pencil") }
                                                }
                                                Button(role: .destructive, action: { if let id = message.id { viewModel.deleteMessage(messageID: id) } }) { Label("Διαγραφή", systemImage: "trash") }
                                            }
                                        }
                                    }
                                    
                                    if !isMe { Spacer() }
                                }
                                .padding(.bottom, (message.reactions?.isEmpty ?? true) ? 0 : 8)
                                
                                if !readersOfThisMessage.isEmpty {
                                    HStack(spacing: 4) { ForEach(readersOfThisMessage, id: \.self) { readerID in UserProfileImageView(urlString: viewModel.userProfileImages[readerID], size: 14) } }.padding(.trailing, 4)
                                }
                            }
                            .padding(.horizontal)
                            .onAppear { if !isSending { viewModel.markMessageAsRead(message: message) } }
                        }
                    }
                    // Σκρολάρισμα όταν αλλάζει το σύνολο των μηνυμάτων (μαζί με τα temp)
                    .onChange(of: allMessages.count) { _, _ in
                        if let lastMessage = allMessages.last {
                            withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let lastMessage = allMessages.last { proxy.scrollTo(lastMessage.id, anchor: .bottom) }
                        }
                    }
                }
            }
            
            Divider()
            
            // MARK: - Μπάρα Εισαγωγής & Preview Box
            VStack(spacing: 8) {
                if isEditingMode {
                    HStack {
                        Text("Επεξεργασία μηνύματος...").font(.caption).foregroundColor(.secondary).italic()
                        Spacer()
                        Button("Ακύρωση") { isEditingMode = false; editingMessageID = nil; messageText = "" }.font(.caption).foregroundColor(.red)
                    }.padding(.horizontal).padding(.top, 4)
                }
                
                // ΝΕΟ: Αναβαθμισμένο Preview Box με Ακαριαίο Τοπικό Thumbnail
                if let mediaItem = selectedMediaItem {
                    HStack {
                        ZStack(alignment: .topTrailing) {
                            if let uiImage = getPreviewImage(for: mediaItem) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(8)
                                    .overlay(
                                        Group {
                                            if case .video = mediaItem {
                                                Image(systemName: "video.fill")
                                                    .font(.system(size: 10)).foregroundColor(.white)
                                                    .padding(4).background(Color.black.opacity(0.6)).clipShape(Circle()).padding(4)
                                            }
                                        }, alignment: .bottomLeading
                                    )
                            } else {
                                ProgressView().frame(width: 70, height: 70)
                            }
                            
                            Button(action: { selectedMediaItem = nil }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red).background(Color(.systemBackground).clipShape(Circle()))
                            }
                            .offset(x: 6, y: -6)
                        }
                        .padding(.leading, 12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Επιλεγμένο αρχείο").font(.footnote).fontWeight(.bold)
                            Text("Γράψε μια λεζάντα παρακάτω...").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6).background(Color.gray.opacity(0.08)).cornerRadius(10).padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                HStack(spacing: 12) {
                    if !isEditingMode {
                        Button(action: { showMediaPicker = true }) {
                            Image(systemName: "paperclip").font(.title2).foregroundColor(Color(hex: "#948979"))
                        }
                    }
                    
                    TextField(selectedMediaItem != nil ? "Προσθήκη λεζάντας..." : (isEditingMode ? "Διόρθωση μηνύματος..." : "Μήνυμα..."), text: $messageText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(isEditingMode ? "Ενημέρωση" : "Αποστολή") {
                        if let mediaItem = selectedMediaItem {
                            viewModel.sendMediaMessage(item: mediaItem, caption: messageText)
                            selectedMediaItem = nil
                            messageText = ""
                        } else if !messageText.isEmpty {
                            if isEditingMode, let msgID = editingMessageID {
                                viewModel.editMessage(messageID: msgID, newText: messageText)
                                isEditingMode = false
                                editingMessageID = nil
                            } else {
                                viewModel.sendMessage(text: messageText)
                            }
                            messageText = ""
                        }
                    }
                    .buttonStyle(.borderedProminent).tint(Color(hex: "#948979"))
                }
                .padding(.horizontal).padding(.bottom, 8)
                .padding(.top, selectedMediaItem != nil || isEditingMode ? 0 : 8)
            }
            .background(Color(.systemBackground))
        }
        .onAppear { tabBarMode = .hidden }
        .onDisappear { tabBarMode = .store }
        .sheet(isPresented: $showMediaPicker) {
            ChatMediaPicker(isPresented: $showMediaPicker) { selectedMedia in
                withAnimation(.spring()) { self.selectedMediaItem = selectedMedia }
            }
        }
        .fullScreenCover(item: $fullscreenMediaMessage) { message in
            if let url = message.mediaURL, let type = message.mediaType { FullscreenMediaView(urlString: url, type: type) }
        }
    }
    
    // Helper: Εξαγωγή εικόνας για το Preview Box χωρίς καμία καθυστέρηση
    private func getPreviewImage(for item: ChatMediaItem) -> UIImage? {
        switch item {
        case .image(let data):
            return UIImage(data: data)
        case .video(let url):
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.0, preferredTimescale: 60)
            if let imageRef = try? generator.copyCGImage(at: time, actualTime: nil) {
                return UIImage(cgImage: imageRef)
            }
            return nil
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
