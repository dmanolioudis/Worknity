//
//  UserProfileImageView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 9/7/26.
//


import SwiftUI

struct UserProfileImageView: View {
    let urlString: String?
    var size: CGFloat = 16 // Δυναμικό μέγεθος (προεπιλογή 16)
    
    var body: some View {
        Group {
            if let urlString = urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                // Fallback εικονίδιο αν ο χρήστης δεν έχει φωτογραφία
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.18) // Προσαρμογή του icon ανάλογα με το μέγεθος
                            .foregroundColor(.white)
                    )
                    .clipShape(Circle())
            }
        }
    }
}
