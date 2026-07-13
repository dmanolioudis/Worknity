//
//  ProfileEditView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 8/6/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct ProfileEditView: View {
    @State private var fullName = ""
    @State private var dateOfBirth = ""
    @State private var gender: String = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var profileImage: UIImage?
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .foregroundColor(mainColor)
                        }
                        Spacer()
                        Text("My Profile")
                            .font(.title3).bold()
                            .padding(.trailing)
                        Spacer()
                    }
                    .padding(.horizontal)
                    ScrollView {
                    VStack {
                        Button(action: { showImagePicker = true }) {
                            if let image = selectedImage ?? profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedImage)
                        }
                    }

                    Group {
                        SectionHeader(title: "Basic Detail")
                        CustomTextField(placeholder: "Full name", text: $fullName)
                        CustomTextField(placeholder: "Date of birth", text: $dateOfBirth)

                        HStack(spacing: 16) {
                            GenderButton(title: "Male", isSelected: gender == "Male") {
                                gender = "Male"
                            }
                            GenderButton(title: "Female", isSelected: gender == "Female") {
                                gender = "Female"
                            }
                        }
                    }

                    Group {
                        SectionHeader(title: "Contact Detail")

                        CustomTextField(placeholder: "Mobile number", text: $phone, keyboardType: .phonePad)
                        CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
                    }

                    

                    Button(action: {
                        updateUserData()
                    }) {
                        Text("Save")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(mainColor)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .onAppear(perform: fetchUserData)
            .navigationBarHidden(true)
        }
        .navigationBarBackButtonHidden(true)

    }

    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore().collection("users")
            .whereField("uid", isEqualTo: user.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user: \(error)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("User document not found")
                    return
                }

                let data = document.data()
                self.fullName = data["fullName"] as? String ?? ""
                self.email = data["email"] as? String ?? ""
                self.phone = data["phone"] as? String ?? ""
                self.dateOfBirth = data["dateOfBirth"] as? String ?? ""
                self.gender = data["gender"] as? String ?? ""
               
                if let urlStr = data["photoURL"] as? String, let url = URL(string: urlStr) {
                    downloadImage(from: url) { image in
                        DispatchQueue.main.async {
                            self.profileImage = image
                        }
                    }
                }
            }
    }

    private func updateUserData() {
        guard let users = Auth.auth().currentUser else { return }

        var userData: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "phone": phone,
            "dateOfBirth": dateOfBirth,
            "gender": gender,

        ]

        if let image = selectedImage {
            uploadProfileImage(image) { url in
                if let url = url {
                    userData["photoURL"] = url.absoluteString
                }

                Firestore.firestore().collection("users")
                    .document(users.uid)
                    .updateData(userData) { error in
                        if let error = error {
                            print("Error updating user: \(error)")
                        }
                    }
            }
        } else {
            Firestore.firestore().collection("users")
                .document(users.uid)
                .updateData(userData) { error in
                    if let error = error {
                        print("Error updating user: \(error)")
                    }
                }
        }
    }

    private func uploadProfileImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Storage.storage().reference().child("profileImages/\(uid).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.4) else { return }

        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Failed to upload image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url)
                }
            }
        }
    }


    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}

// MARK: - UI Components

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .frame(height: 50)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .keyboardType(keyboardType)
    }
}

struct SectionHeader: View {
    var title: String
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct GenderButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? mainColor : Color(UIColor.systemGray5))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(10)
        }
    }
}



#Preview {
    ProfileEditView()
}
