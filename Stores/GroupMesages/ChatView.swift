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
    var conversationName: String = AppL10n.text("Γενική ομαδική συνομιλία")
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var messageText = ""
    @State private var selectedMessageID: String? = nil
    @State private var editingMessageID: String? = nil
    @State private var isEditingMode = false
    @State private var showMediaPicker = false
    @State private var fullscreenMediaMessage: ChatMessage? = nil
    @State private var selectedMediaItem: ChatMediaItem? = nil
    @State private var photoSaveAlert: PhotoSaveAlert? = nil
    
    var body: some View {
        // Συνδυασμός κανονικών μηνυμάτων και αυτών που αποστέλλονται αυτή τη στιγμή
        let allMessages = viewModel.messages + viewModel.sendingMessages
        
        VStack(spacing: 0) {
            conversationHeader
            if let error = viewModel.operationError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }

            // MARK: - Μηνύματα Συνομιλίας
            ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(allMessages.enumerated()), id: \.element.id) { item in
                            let index = item.offset
                            let message = item.element
                            
                            let beginsDay = index == 0 || !Calendar.current.isDate(allMessages[index - 1].timestamp, inSameDayAs: message.timestamp)
                            let isFirstInBlock = index == 0 || startsNewMessageGroup(message, after: allMessages[index - 1])
                            let isLastInBlock = index == allMessages.count - 1 || startsNewMessageGroup(allMessages[index + 1], after: message)
                            let isMe = message.senderID == Auth.auth().currentUser?.uid
                            let isSending = message.isSending ?? false // Έλεγχος αν στέλνεται τώρα
                            
                            let readersOfThisMessage = viewModel.lastReadMessageForUser
                                .filter { $0.value == message.id }
                                .map { $0.key }
                            
                            if beginsDay {
                                Text(message.timestamp, format: .dateTime.day().month(.wide).year())
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }

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
                                        Spacer(minLength: 40)
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
                                                    Button {
                                                        fullscreenMediaMessage = message
                                                    } label: {
                                                        Group {
                                                            if mediaType == "image" {
                                                                CachedRemoteImage(url: URL(string: mediaURL)) { img in
                                                                    img.resizable().scaledToFill()
                                                                } placeholder: {
                                                                    ProgressView().frame(width: 220, height: 220)
                                                                }
                                                                .frame(width: 220, height: 220)
                                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                            } else if mediaType == "video" {
                                                                // ΝΕΟ: Φόρτωση του έτοιμου Thumbnail από το cloud (Σφαίρα!)
                                                                if let thumbURL = message.thumbnailURL, let url = URL(string: thumbURL) {
                                                                    CachedRemoteImage(url: URL(string: thumbURL)) { img in
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
                                                        }
                                                        .contentShape(RoundedRectangle(cornerRadius: 12))
                                                    }
                                                    .buttonStyle(.plain)
                                                    .accessibilityLabel(mediaType == "video" ? "Άνοιγμα βίντεο" : "Άνοιγμα φωτογραφίας")

                                                    // Λεζάντα
                                                    if message.text != "🖼️ Φωτογραφία" && message.text != "🎥 Βίντεο" {
                                                        Text(message.text)
                                                            .font(.body)
                                                            .padding(.horizontal, 4).padding(.bottom, 4)
                                                            .onTapGesture { toggleMessageDetails(message) }
                                                    }
                                                }
                                                .padding(6)
                                                .background { StoreBubbleSurface(outgoing: isMe) }
                                                .foregroundColor(.primary)
                                            } else {
                                                // Μήνυμα Κειμένου
                                                Text(message.text)
                                                    .font(.body)
                                                    .lineSpacing(2)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .padding(.horizontal, 15)
                                                    .padding(.vertical, 11)
                                                    .background { StoreBubbleSurface(outgoing: isMe) }
                                                    .foregroundColor(.primary)
                                                    .onTapGesture { toggleMessageDetails(message) }
                                            }
                                            
                                            // Reactions Badge
                                            if let reactions = message.reactions, !reactions.isEmpty {
                                                let uniqueEmojis = Array(Set(reactions.values)).prefix(3)
                                                HStack(spacing: 2) {
                                                    ForEach(uniqueEmojis, id: \.self) { emoji in Text(emoji).font(.system(size: 11)) }
                                                    if reactions.count > 1 { Text("\(reactions.count)").font(.system(size: 9, weight: .bold)).foregroundColor(.secondary) }
                                                }
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(StoreDesign.surface, in: Capsule())
                                                .overlay(Capsule().strokeBorder(StoreDesign.line, lineWidth: 1))
                                                .offset(x: isMe ? -8 : 8, y: 8).zIndex(2)
                                            }
                                        }
                                        
                                        if selectedMessageID == message.id || isLastInBlock || isSending {
                                            HStack(spacing: 5) {
                                                if selectedMessageID == message.id {
                                                    Text(message.timestamp, style: .date)
                                                }
                                                if isSending {
                                                    Text("Αποστολή…")
                                                } else {
                                                    Text(formatTime(message.timestamp))
                                                }
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.top, 3)
                                            .onTapGesture { toggleMessageDetails(message) }
                                        }

                                        if selectedMessageID == message.id, message.mediaURL != nil, !isSending {
                                            Button {
                                                fullscreenMediaMessage = message
                                            } label: {
                                                Label(message.mediaType == "video" ? "Προβολή βίντεο" : "Προβολή φωτογραφίας", systemImage: "arrow.up.left.and.arrow.down.right")
                                                    .font(.caption.weight(.medium))
                                                    .padding(.vertical, 10)
                                            }
                                            .buttonStyle(.plain)
                                            .foregroundStyle(StoreDesign.ink)
                                        }
                                    }
                                    .id(message.id)
                                    .accessibilityAction(named: Text("Στοιχεία μηνύματος")) {
                                        toggleMessageDetails(message)
                                    }
                                    .contextMenu {
                                        if !isSending {
                                            Button("Στοιχεία μηνύματος", systemImage: "info.circle") {
                                                toggleMessageDetails(message)
                                            }
                                            Menu("Προσθήκη Αντίδρασης... 🎭") {
                                                Button("❤️ Καρδιά") { viewModel.handleReaction(message: message, emoji: "❤️") }
                                                Button("👍 Μου αρέσει") { viewModel.handleReaction(message: message, emoji: "👍") }
                                                Button("👎 Δεν μου αρέσει") { viewModel.handleReaction(message: message, emoji: "👎") }
                                            }
                                            if message.mediaType == "image",
                                               let mediaURL = message.mediaURL,
                                               let url = URL(string: mediaURL) {
                                                Button {
                                                    saveChatImage(from: url)
                                                } label: {
                                                    Label("Αποθήκευση φωτογραφίας", systemImage: "square.and.arrow.down")
                                                }
                                            }
                                            if message.mediaType == "video",
                                               let mediaURL = message.mediaURL,
                                               let url = URL(string: mediaURL) {
                                                Button {
                                                    saveChatVideo(from: url)
                                                } label: {
                                                    Label("Αποθήκευση βίντεο", systemImage: "square.and.arrow.down")
                                                }
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
                                    
                                    if !isMe { Spacer(minLength: 40) }
                                }
                                .padding(.bottom, (message.reactions?.isEmpty ?? true) ? 0 : 8)
                                
                                if !readersOfThisMessage.isEmpty {
                                    HStack(spacing: 4) { ForEach(readersOfThisMessage, id: \.self) { readerID in UserProfileImageView(urlString: viewModel.userProfileImages[readerID], size: 14) } }.padding(.trailing, 4)
                                }
                            }
                            .padding(.horizontal)
                            .onAppear {
                                if !isSending {
                                    viewModel.markMessageAsRead(message: message)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if allMessages.isEmpty {
                    conversationIntroduction
                        .allowsHitTesting(false)
                }
            }
            
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
                    .padding(.vertical, 10).storeCard(radius: 18).padding(.horizontal, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                HStack(alignment: .bottom, spacing: 10) {
                    if !isEditingMode {
                        Button(action: { showMediaPicker = true }) {
                            Image(systemName: "plus")

                        }
                        .buttonStyle(StoreComposerButtonStyle())
                        .accessibilityLabel("Προσθήκη φωτογραφίας ή βίντεο")
                    }

                    TextField(LocalizedStringKey(selectedMediaItem != nil ? "Προσθήκη λεζάντας..." : (isEditingMode ? "Διόρθωση μηνύματος..." : "Μήνυμα...")), text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 4)
                        .frame(minHeight: 44)
                    
                    Button {
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
                    } label: {
                        Image(systemName: isEditingMode ? "checkmark" : "arrow.up")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(StoreComposerButtonStyle(prominent: true))
                    .accessibilityLabel(isEditingMode ? "Ενημέρωση μηνύματος" : "Αποστολή μηνύματος")
                }
                .padding(.horizontal, StoreDesign.composerInset)
                .padding(.bottom, StoreDesign.composerInset)
                .padding(.top, selectedMediaItem != nil || isEditingMode ? 0 : 8)
            }
            .storeGlass(radius: StoreDesign.composerRadius)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .background { StoreBackdrop(chat: true) }
        .tint(StoreDesign.ink)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showMediaPicker) {
            ChatMediaPicker(isPresented: $showMediaPicker) { selectedMedia in
                withAnimation(.spring()) { self.selectedMediaItem = selectedMedia }
            }
        }
        .fullScreenCover(item: $fullscreenMediaMessage) { message in
            if let url = message.mediaURL, let type = message.mediaType { FullscreenMediaView(urlString: url, type: type) }
        }
        .alert(item: $photoSaveAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }

    private var conversationHeader: some View {
        HStack(spacing: 12) {
            StoreIcon(symbol: "person.3.fill")
            VStack(alignment: .leading, spacing: 3) {
                Text("Η ομάδα μας")
                    .font(.headline)
                Text(conversationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            // Show only real profiles already provided by the conversation.
            if !dynamicTypeSize.isAccessibilitySize {
                HStack(spacing: -8) {
                ForEach(Array(viewModel.userNames.keys.sorted().prefix(3)), id: \.self) { userID in
                    UserProfileImageView(urlString: viewModel.userProfileImages[userID], size: 28)
                        .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 2))
                        .accessibilityLabel(viewModel.userNames[userID] ?? "")
                }
                }
            }
        }
        .padding(12)
        .storeCard(radius: 24)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var conversationIntroduction: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(StoreDesign.ink)
                .frame(width: 88, height: 88)
                .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 30))
                .accessibilityHidden(true)
            Text("Εδώ συναντιέται η ομάδα")
                .font(.title3.weight(.semibold))
            Text("Μια ερώτηση, μια ενημέρωση ή μια καλημέρα.\nΟ κοινός σας χώρος για κάθε μέρα.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Label("Μηνύματα · Φωτογραφίες · Βίντεο", systemImage: "paperclip")
                .font(.caption)
                .foregroundStyle(StoreDesign.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(24)
        .frame(maxWidth: 360)
    }

    /// A new sender, day, or pause of over five minutes starts a new visual group.
    private func startsNewMessageGroup(_ current: ChatMessage, after previous: ChatMessage) -> Bool {
        current.senderID != previous.senderID
            || !Calendar.current.isDate(current.timestamp, inSameDayAs: previous.timestamp)
            || current.timestamp.timeIntervalSince(previous.timestamp) > 5 * 60
    }

    private func toggleMessageDetails(_ message: ChatMessage) {
        guard let id = message.id else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedMessageID = selectedMessageID == id ? nil : id
        }
    }

    private func saveChatImage(from url: URL) {
        PhotoLibrarySaver.saveImage(from: url) { result in
            switch result {
            case .success:
                photoSaveAlert = PhotoSaveAlert(title: "Αποθηκεύτηκε", message: "Η φωτογραφία προστέθηκε στη Συλλογή Φωτογραφιών.")
            case .failure(let error):
                photoSaveAlert = PhotoSaveAlert(title: "Αποτυχία αποθήκευσης", message: error.localizedDescription)
            }
        }
    }

    private func saveChatVideo(from url: URL) {
        PhotoLibrarySaver.saveVideo(from: url) { result in
            switch result {
            case .success:
                photoSaveAlert = PhotoSaveAlert(title: "Αποθηκεύτηκε", message: "Το βίντεο προστέθηκε στη Συλλογή Φωτογραφιών.")
            case .failure(let error):
                photoSaveAlert = PhotoSaveAlert(title: "Αποτυχία αποθήκευσης", message: error.localizedDescription)
            }
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
        formatter.locale = AppPreferences.shared.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct PhotoSaveAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


struct StoreConversationView: View {
    let conversation: StoreConversation
    @StateObject private var access: StoreAccessViewModel
    @StateObject private var chat: ChatViewModel
    @StateObject private var conversations: StoreConversations
    @State private var showSettings = false

    init(storeID: String, conversation: StoreConversation) {
        self.conversation = conversation
        _access = StateObject(wrappedValue: StoreAccessViewModel(storeID: storeID))
        _chat = StateObject(wrappedValue: ChatViewModel(storeID: storeID, groupID: conversation.groupID, startListening: false))
        _conversations = StateObject(wrappedValue: StoreConversations(storeID: storeID))
    }

    private var currentConversation: StoreConversation {
        if conversation.id == "general" { return StoreConversation(id: "general", name: access.chatName, participantIDs: ConversationAccess.participants(in: access.data, key: "generalChatParticipantIDs")) }
        return conversations.groups.first { $0.id == conversation.id } ?? conversation
    }

    private var hasAccess: Bool {
        guard !access.isLoading, access.error == nil else { return false }
        if conversation.id != "general" {
            guard !conversations.isLoading, conversations.error == nil,
                  conversations.groups.contains(where: { $0.id == conversation.id }) else { return false }
        }
        return ConversationAccess.allows(uid: Auth.auth().currentUser?.uid ?? "",
            storeMembers: access.roles.participants, participantIDs: currentConversation.participantIDs)
    }

    var body: some View {
        Group {
            if hasAccess {
                ChatView(viewModel: chat, conversationName: currentConversation.name)
            } else if access.isLoading || (conversation.id != "general" && conversations.isLoading) {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView("Δεν έχεις πρόσβαση σε αυτή τη συνομιλία.", systemImage: "lock")
            }
        }
            .task(id: hasAccess) {
                if hasAccess { chat.fetchMessages() }
                else { chat.stopListening(); showSettings = false }
            }
            .onDisappear { chat.stopListening() }
            .navigationTitle(currentConversation.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hasAccess && access.can(.groups) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showSettings = true } label: { Image(systemName: "gearshape") }
                            .accessibilityLabel("Ρυθμίσεις συνομιλίας")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                ConversationSettingsView(access: access, conversation: currentConversation)
            }
    }
}
