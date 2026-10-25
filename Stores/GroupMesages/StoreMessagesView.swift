//
//  StoreMessagesView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 8/7/26.
//


import SwiftUI
import FirebaseAuth

struct StoreMessagesView: View {
    let storeID: String
    var onOpenChat: ((StoreConversation) -> Void)? = nil
    var chatName: String = AppL10n.text("Γενική Ομαδική Συνομιλία")
    @State private var selectedConversation: StoreConversation?
    @State private var showCreateGroup = false
    @StateObject private var access: StoreAccessViewModel
    @StateObject private var conversations: StoreConversations

    init(storeID: String, onOpenChat: ((StoreConversation) -> Void)? = nil, chatName: String = AppL10n.text("Γενική Ομαδική Συνομιλία")) {
        self.storeID = storeID; self.onOpenChat = onOpenChat; self.chatName = chatName
        _access = StateObject(wrappedValue: StoreAccessViewModel(storeID: storeID))
        _conversations = StateObject(wrappedValue: StoreConversations(storeID: storeID))
    }
    
    private var availableConversations: [StoreConversation] {
        let general = StoreConversation(id: "general", name: chatName,
            participantIDs: ConversationAccess.participants(in: access.data, key: "generalChatParticipantIDs"))
        let uid = Auth.auth().currentUser?.uid ?? ""
        return ([general] + conversations.groups).filter {
            ConversationAccess.allows(uid: uid, storeMembers: access.roles.participants, participantIDs: $0.participantIDs)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                StorePageHeader(title: "Μηνύματα", subtitle: "Οι συνομιλίες του καταστήματός σου.", symbol: "bubble.left.and.bubble.right")

                Text("ΟΜΑΔΙΚΕΣ ΣΥΝΟΜΙΛΙΕΣ")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .accessibilityAddTraits(.isHeader)

                if access.can(.groups) {
                    Button { showCreateGroup = true } label: {
                        Label("Νέα ομάδα", systemImage: "plus")
                    }
                    .buttonStyle(StorePrimaryButtonStyle())
                    .padding(.horizontal, 20)
                }
                if let error = conversations.error {
                    Text(error).font(.footnote).foregroundStyle(.red).padding(.horizontal, 20)
                }
                ForEach(availableConversations) { conversation in
                Button {
                    if let onOpenChat {
                        onOpenChat(conversation)
                    } else {
                        selectedConversation = conversation
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 14) {
                            StoreIcon(symbol: "person.3.fill")
                            VStack(alignment: .leading, spacing: 6) {
                                Text(conversation.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(conversation.participantIDs == nil ? "Όλη η ομάδα, σε έναν κοινό χώρο." : "Συνομιλία επιλεγμένων μελών")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "text.bubble")
                            Text("Μηνύματα")
                            Text("·")
                            Image(systemName: "photo.on.rectangle")
                            Text("Πολυμέσα")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Rectangle().fill(StoreDesign.line).frame(height: 1)

                        HStack {
                            Text("Άνοιγμα συνομιλίας")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(StoreDesign.ink)
                    }
                    .padding(20)
                    .storeCard(radius: 26)
                    .contentShape(RoundedRectangle(cornerRadius: 26))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityLabel(conversation.name)
                .accessibilityHint("Ανοίγει τα μηνύματα της ομάδας")
                }
            }
            .padding(.bottom, 24)
        }
        .background { StoreBackdrop() }
        .sheet(isPresented: $showCreateGroup) { ConversationSettingsView(access: access) }
        .navigationDestination(item: $selectedConversation) { conversation in
            StoreConversationView(storeID: storeID, conversation: conversation)
                .toolbar(.hidden, for: .tabBar)
                .tint(StoreDesign.ink)
        }
    }
}
