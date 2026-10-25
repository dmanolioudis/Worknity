//
//  Root.swift
//  Worknity
//
//  Created by Dee Manolioudis on 3/6/25.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    var startupNamespace: Namespace.ID? = nil
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        if authViewModel.isAuthenticated {
            RootTabView()
                .environmentObject(authViewModel)
        } else {
            WelcomeView(startupNamespace: startupNamespace)
                .environmentObject(authViewModel)
        }
    }
}

