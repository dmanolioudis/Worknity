//
//  FullscreenMediaView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 9/7/26.
//


// FullscreenMediaView.swift
import SwiftUI
import AVKit

struct FullscreenMediaView: View {
    let urlString: String
    let type: String
    @Environment(\.dismiss) var dismiss
    
    // ΝΕΟ: Κρατάμε τον AVPlayer σε @State για να μην καταστρέφεται από τα redraws του SwiftUI
    @State private var player: AVPlayer?
    @State private var isLoadingVideo = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if type == "image" {
                    // Προβολή Φωτογραφίας
                    AsyncImage(url: URL(string: urlString)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                } else if type == "video" {
                    // Προβολή Βίντεο
                    if let player = player {
                        VideoPlayer(player: player)
                            .ignoresSafeArea()
                            .onAppear {
                                // Ξεκινάει αυτόματα το βίντεο μόλις εμφανιστεί ο player
                                player.play()
                            }
                            .onDisappear {
                                // Σταματάει το βίντεο αν ο χρήστης βγει, για να μην ακούγεται ο ήχος στο background
                                player.pause()
                            }
                    } else {
                        // Εμφάνιση loading indicator όσο προετοιμάζεται ο player
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Φόρτωση βίντεο...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Πίσω")
                        }
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    }
                }
            }
            // Αρχικοποίηση του Player σωστά στο onAppear
            .onAppear {
                setupPlayer()
            }
        }
    }
    
    private func setupPlayer() {
        guard type == "video", player == nil else { return }
        
        // Ασφαλής μετατροπή του String σε URL (υποστηρίζει και τα tokens του Firebase)
        if let url = URL(string: urlString) {
            // Δημιουργία του player στο Main Thread
            DispatchQueue.main.async {
                self.player = AVPlayer(url: url)
                self.isLoadingVideo = false
            }
        }
    }
}
