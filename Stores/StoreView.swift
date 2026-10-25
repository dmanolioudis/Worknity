//
//  StoreView.swift
//  Worknity
//

import SwiftUI

struct StoreView: View {
    var storename: String
    var storeID: String
    @Binding var selectedTab: STabs
    let onBack: () -> Void
    

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                StoreTabContentView(storeID: storeID, storename: storename, tab: .main)
                    .tabItem { Label("Νέα", systemImage: "newspaper") }
                    .tag(STabs.main)

                StoreTabContentView(storeID: storeID, storename: storename, tab: .messages)
                    .tabItem { Label("Μηνύματα", systemImage: "captions.bubble") }
                    .tag(STabs.messages)

                StoreTabContentView(storeID: storeID, storename: storename, tab: .schedule)
                    .tabItem { Label("Πρόγραμμα", systemImage: "calendar.day.timeline.left") }
                    .tag(STabs.schedule)
            }
        }
        .tint(StoreDesign.ink)
    }
}

struct StoreTabContentView: View {
    let storeID: String
    let storename: String
    let tab: STabs
    var onOpenChat: ((StoreConversation) -> Void)? = nil

    @State private var showStoreSettings = false
    @StateObject private var access: StoreAccessViewModel

    init(storeID: String, storename: String, tab: STabs, onOpenChat: ((StoreConversation) -> Void)? = nil) {
        self.storeID = storeID
        self.storename = storename
        self.tab = tab
        self.onOpenChat = onOpenChat
        _access = StateObject(wrappedValue: StoreAccessViewModel(storeID: storeID))
    }

    var body: some View {
        Group {
            switch tab {
            case .main:
                StoreMainView(storeID: storeID, storename: storename)
            case .messages:
                StoreMessagesView(storeID: storeID, onOpenChat: onOpenChat, chatName: access.chatName)
            case .schedule:
                StoreScheduleView(storeID: storeID)
            }
        }
        .tint(StoreDesign.ink)
        .navigationTitle(access.name.isEmpty ? storename : access.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if access.isManager {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showStoreSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.body.weight(.medium))
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Ρυθμίσεις καταστήματος")
                }
            }
        }
        .sheet(isPresented: $showStoreSettings) {
            StoreSettingsView(access: access)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}
