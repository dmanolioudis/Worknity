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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AccountPageBanner(title: "Το προφίλ σου", subtitle: "Η φωτογραφία και τα προσωπικά σου στοιχεία.", symbol: "person.crop.circle")

                VStack(spacing: 14) {
                    Button { showImagePicker = true } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let image = selectedImage ?? profileImage {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable().scaledToFit()
                                        .foregroundStyle(StoreDesign.ink)
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            Image(systemName: "camera.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(StoreDesign.actionLabel)
                                .frame(width: 34, height: 34)
                                .background(StoreDesign.actionFill, in: Circle())
                                .overlay(Circle().strokeBorder(StoreDesign.surface, lineWidth: 3))
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Αλλαγή φωτογραφίας προφίλ")

                    VStack(spacing: 4) {
                        Text(fullName.isEmpty ? AppL10n.text("Η φωτογραφία σου") : fullName)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Button("Αλλαγή φωτογραφίας") { showImagePicker = true }
                            .font(.subheadline)
                            .foregroundStyle(StoreDesign.ink)
                            .frame(minHeight: 44)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .storeCard()

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Προσωπικά στοιχεία")
                    CustomTextField(placeholder: "Ονοματεπώνυμο", text: $fullName, contentType: .name)
                    CustomTextField(placeholder: "Ημερομηνία γέννησης", text: $dateOfBirth)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Φύλο").font(.subheadline.weight(.medium))
                        let layout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(spacing: 10))
                            : AnyLayout(HStackLayout(spacing: 10))
                        layout {
                            GenderButton(title: "Άνδρας", isSelected: gender == "Male") {
                                gender = "Male"
                            }
                            GenderButton(title: "Γυναίκα", isSelected: gender == "Female") {
                                gender = "Female"
                            }
                        }
                    }
                }
                .padding(20)
                .storeCard()

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Στοιχεία επικοινωνίας")
                    CustomTextField(placeholder: "Κινητό τηλέφωνο", text: $phone, keyboardType: .phonePad, contentType: .telephoneNumber)
                    CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress, contentType: .emailAddress)
                }
                .padding(20)
                .storeCard()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { StoreBackdrop() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: updateUserData) {
                Label("Αποθήκευση αλλαγών", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(StorePrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(StoreDesign.canvas)
        }
        .navigationTitle("Επεξεργασία προφίλ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .tint(StoreDesign.ink)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear(perform: fetchUserData)
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
    var contentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(placeholder))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            TextField(LocalizedStringKey(placeholder), text: $text)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .frame(minHeight: 48)
                .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 14))
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
                .accessibilityLabel(placeholder)
        }
    }
}

struct SectionHeader: View {
    var title: String

    var body: some View {
        Text(LocalizedStringKey(title))
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct GenderButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(LocalizedStringKey(title))
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? StoreDesign.actionLabel : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? StoreDesign.actionFill : StoreDesign.softAccent,
                        in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    NavigationStack { ProfileEditView() }
}
