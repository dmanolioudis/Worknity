//
//  Root.swift
//  Worknity
//
//  Created by Dee Manolioudis on 3/6/25.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        if authViewModel.isAuthenticated {
            RootTabView()
        } else {
            WelcomeView()
                .environmentObject(authViewModel)
        }
    }
}


