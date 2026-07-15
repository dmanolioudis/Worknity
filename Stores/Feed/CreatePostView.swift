//
//  CreatePostView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    let storeID: String
    
    @State private var postContent: String = ""
    
    // Media States
    @State private var selectedImage: UIImage? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var selectedFileURL: URL? = nil
    @State private var selectedFileName: String? = nil
    @State private var mediaType: PostMediaType = .none
    
    // Pickers Triggers
    @State private var showAttachmentMenu = false // Ενιαίο μενού επιλογών
    @State private var showCameraPicker = false   // Trigger για κάμερα
    @State private var showMediaPicker = false    // Trigger για συλλογή
    @State private var showFilePicker = false     // Trigger για έγγραφα
    
    @State private var isUploading = false
    @State private var isPinned = false
    
    let mainColor = Color(hex: "#948979")
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DFD0B8").opacity(0.1).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Text Editor
                        ZStack(alignment: .topLeading) {
                            if postContent.isEmpty {
                                Text("Τι θέλετε να μοιραστείτε με την ομάδα;")
                                    .foregroundColor(.gray.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                            }
                            
                            TextEditor(text: $postContent)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        
                        // --- PREVIEWS ΤΩΝ ΕΠΙΛΕΓΜΕΝΩΝ ΠΟΛΥΜΕΣΩΝ ---
                        if mediaType != .none {
                            VStack {
                                if mediaType == .image, let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else if mediaType == .video {
                                    Label("Επιλέχθηκε Βίντεο", systemImage: "video.fill")
                                        .foregroundColor(mainColor)
                                        .font(.headline)
                                } else if mediaType == .file {
                                    Label(selectedFileName ?? "Αρχείο", systemImage: "doc.fill")
                                        .foregroundColor(.blue)
                                        .font(.headline)
                                }
                                
                                Button(role: .destructive) {
                                    clearMediaSelection()
                                } label: {
                                    Text("Αφαίρεση αρχείου").font(.footnote)
                                }
                                .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        // --- ΤΟ ΝΕΟ ΕΝΙΑΙΟ ΚΟΥΜΠΙ ΣΥΝΗΜΜΕΝΩΝ ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ΠΡΟΣΘΗΚΗ ΣΤΗ ΔΗΜΟΣΙΕΥΣΗ")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            
                            Button(action: { showAttachmentMenu = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "paperclip.circle.fill")
                                        .font(.title3)
                                    Text("Προσθήκη αρχείου ή φωτό")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(mainColor)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 3)
                            }
                        }
                        .padding(.top, 10)
                        // Το Action Sheet που πετάγεται από το κάτω μέρος
                        .confirmationDialog("Επιλέξτε συνημμένο", isPresented: $showAttachmentMenu, titleVisibility: .hidden) {
                            Button {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    showCameraPicker = true
                                } else {
                                    print("Η κάμερα δεν είναι διαθέσιμη (π.χ. σε Simulator)")
                                }
                            } label: {
                                Label("Βγάλτε Φωτογραφία (Κάμερα)", systemImage: "camera")
                            }
                            
                            Button {
                                showMediaPicker = true
                            } label: {
                                Label("Φωτογραφία ή Βίντεο (Συλλογή)", systemImage: "photo.on.rectangle")
                            }
                            
                            Button {
                                showFilePicker = true
                            } label: {
                                Label("Έγγραφο / Αρχείο", systemImage: "doc.badge.plus")
                            }
                            
                            Button("Ακύρωση", role: .cancel) {}
                        }
                        
                        // Pin Toggle
                        Toggle(isOn: $isPinned) {
                            Label("Καρφίτσωμα στην κορυφή", systemImage: "pin.fill")
                                .foregroundColor(isPinned ? .orange : .primary)
                        }
                        .tint(.orange)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationTitle("Νέα Δημοσίευση")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Ακύρωση") { dismiss() }.foregroundColor(mainColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: uploadPost) {
                        if isUploading {
                            ProgressView().tint(mainColor)
                        } else {
                            Text("Δημοσίευση").bold().foregroundColor(postContent.isEmpty ? .gray : mainColor)
                        }
                    }
                    .disabled(postContent.isEmpty || isUploading)
                }
            }
            // 1. Sheet για την Κάμερα
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(image: $selectedImage)
                    .onDisappear {
                        if selectedImage != nil {
                            mediaType = .image
                        }
                    }
            }
            // 2. Sheet για τη Συλλογή
            .sheet(isPresented: $showMediaPicker) {
                UniversalMediaPicker(image: $selectedImage, videoURL: $selectedVideoURL, selectedType: $mediaType)
            }
            // 3. Sheet για τα Έγγραφα
            .sheet(isPresented: $showFilePicker) {
                DocumentPicker(fileURL: $selectedFileURL, fileName: $selectedFileName, selectedType: $mediaType)
            }
        }
    }
    
    private func clearMediaSelection() {
        selectedImage = nil
        selectedVideoURL = nil
        selectedFileURL = nil
        selectedFileName = nil
        mediaType = .none
    }
    
    private func uploadPost() {
        guard let user = Auth.auth().currentUser, !postContent.isEmpty else { return }
        isUploading = true
        
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { snapshot, _ in
            let userData = snapshot?.data()
            let authorName = userData?["fullName"] as? String ?? "Manager"
            let authorProfilePic = userData?["photoURL"] as? String
            
            let fileID = UUID().uuidString
            let folderRef = Storage.storage().reference().child("store_posts/\(storeID)")
            
            if mediaType == .image, let img = selectedImage, let data = img.jpegData(compressionQuality: 0.6) {
                let ref = folderRef.child("\(fileID).jpg")
                ref.putData(data, metadata: nil) { _, _ in
                    ref.downloadURL { url, _ in
                        savePost(authorName: authorName, authorProfilePic: authorProfilePic, mediaURL: url?.absoluteString, type: .image, name: nil)
                    }
                }
            } else if mediaType == .video, let videoURL = selectedVideoURL {
                let ref = folderRef.child("\(fileID).mp4")
                ref.putFile(from: videoURL, metadata: nil) { _, _ in
                    ref.downloadURL { url, _ in
                        savePost(authorName: authorName, authorProfilePic: authorProfilePic, mediaURL: url?.absoluteString, type: .video, name: nil)
                    }
                }
            } else if mediaType == .file, let fileURL = selectedFileURL {
                let filename = selectedFileName ?? "file"
                let ref = folderRef.child("\(fileID)_\(filename)")
                ref.putFile(from: fileURL, metadata: nil) { _, _ in
                    ref.downloadURL { url, _ in
                        savePost(authorName: authorName, authorProfilePic: authorProfilePic, mediaURL: url?.absoluteString, type: .file, name: filename)
                    }
                }
            } else {
                savePost(authorName: authorName, authorProfilePic: authorProfilePic, mediaURL: nil, type: .none, name: nil)
            }
        }
    }
    
    private func savePost(authorName: String, authorProfilePic: String?, mediaURL: String?, type: PostMediaType, name: String?) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let postData: [String: Any] = [
            "storeID": storeID,
            "content": postContent,
            "mediaURL": mediaURL as Any,
            "mediaType": type.rawValue,
            "fileName": name as Any,
            "isPinned": isPinned,
            "timestamp": FieldValue.serverTimestamp(),
            "authorID": uid,
            "authorName": authorName,
            "authorProfilePic": authorProfilePic as Any,
            "likes": []
        ]
        
        db.collection("stores").document(storeID).collection("posts").document().setData(postData) { _ in
            isUploading = false
            dismiss()
        }
    }
}
