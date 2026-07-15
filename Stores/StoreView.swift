//
//  StoreView.swift
//  Worknity
//

import SwiftUI

struct StoreView: View {
    var storename: String
    var storeID: String
    @Binding var tabBarMode: TabBarMode
    @Binding var selectedTab: STabs
    
    // State για να ανοίγει το sheet της προσθήκης μέλους
    @State private var showAddMember = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch selectedTab {
                case .main:
                    // Καλεί το νέο δυναμικό Feed
                    StoreMainView(storeID: storeID, storename: storename)
                case .messages:
                    StoreMessagesView(storeID: storeID, tabBarMode: $tabBarMode)
                case .schedule:
                    StoreScheduleView(storeID: storeID)
                }
            }
            .navigationTitle(storename)
            .navigationBarTitleDisplayMode(.inline)
            // Τοποθέτηση του κουμπιού πάνω δεξιά
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddMember = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#948979"))
                    }
                }
            }
            // Το sheet που ανοίγει για την προσθήκη μέλους
            .sheet(isPresented: $showAddMember) {
                AddMembersView(storeID: storeID)
                    .presentationDetents([.height(300)])
                    .presentationBackground(.thinMaterial)
            }
        }
        .onAppear {
            tabBarMode = .store
        }
    }
}

