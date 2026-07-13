//
//  StoreMessagesView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 8/7/26.
//


import SwiftUI

struct StoreMessagesView: View {
    let storeID: String
    @Binding var tabBarMode: TabBarMode
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Γενική Ομαδική Συνομιλία") {
                    ChatView(viewModel: ChatViewModel(storeID: storeID), tabBarMode: $tabBarMode)
                }
            }
            .navigationTitle("Συνομιλίες")
        }
    }
}
