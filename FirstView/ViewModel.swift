//
//  ViewModel.swift
//  Worknity
//
//  Created by Dee Manolioudis on 3/6/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import FirebaseStorage

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = Auth.auth().currentUser != nil
    
    private var db = Firestore.firestore()

    func signIn(email: String, password: String, onError: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    onError(error.localizedDescription)
                } else {
                    self.isAuthenticated = true
                }
            }
        }
    }

    func register(fullName: String, dateOfBirth: String, gender: String, username: String, email: String, password: String, phone: String, image: UIImage?, onError: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    onError(error.localizedDescription)
                    return
                }

                guard let uid = result?.user.uid else {
                    onError("Failed to get user ID.")
                    return
                }

                // Ανέβασμα φωτογραφίας αν υπάρχει
                if let imageData = image?.jpegData(compressionQuality: 0.5) {
                    let storageRef = Storage.storage().reference().child("profile_images/\(username).jpg")
                    storageRef.putData(imageData, metadata: nil) { metadata, error in
                        if let error = error {
                            onError("Image upload failed: \(error.localizedDescription)")
                            return
                        }

                        storageRef.downloadURL { url, error in
                            if let error = error {
                                onError("Failed to get download URL: \(error.localizedDescription)")
                                return
                            }

                            let userData: [String: Any] = [
                                "fullName": fullName,
                                "username": username,
                                "email": email,
                                "phone": phone,
                                "uid": uid,
                                "photoURL": url?.absoluteString ?? "",
                                "dateOfBirth": dateOfBirth.isEmpty ? "" : dateOfBirth,
                                "gender": gender.isEmpty ? "" : gender,

                            ]

                            self.db.collection("users").document(uid).setData(userData) { error in
                                if let error = error {
                                    onError("Firestore error: \(error.localizedDescription)")
                                } else {
                                    self.isAuthenticated = true
                                }
                            }
                        }
                    }
                } else {
                    let userData: [String: Any] = [
                        "fullName": fullName,
                        "username": username,
                        "email": email,
                        "phone": phone,
                        "uid": uid,
                        "dateOfBirth": dateOfBirth.isEmpty ? "" : dateOfBirth,
                        "gender": gender.isEmpty ? "" : gender,
                        "photoURL": "" // Κενό αν δεν υπάρχει εικόνα
                    ]

                    self.db.collection("users").document(uid).setData(userData) { error in
                        if let error = error {
                            onError("Firestore error: \(error.localizedDescription)")
                        } else {
                            self.isAuthenticated = true
                        }
                    }
                }
            }
        }
    }


    func signOut() {
        try? Auth.auth().signOut()
        isAuthenticated = false
    }
}
