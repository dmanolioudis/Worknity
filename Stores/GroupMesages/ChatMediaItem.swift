//
//  ChatMediaItem.swift
//  Worknity
//
//  Created by Dee Manolioudis on 9/7/26.
//


// ChatMediaPicker.swift
import SwiftUI
import PhotosUI

enum ChatMediaItem {
    case image(Data)
    case video(URL)
}

struct ChatMediaPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onMediaSelected: (ChatMediaItem) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        // Επιτρέπουμε και εικόνες και βίντεο
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ChatMediaPicker

        init(_ parent: ChatMediaPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { return }

            // 1. Έλεγχος αν είναι Εικόνα
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let uiImage = image as? UIImage,
                       let data = uiImage.jpegData(compressionQuality: 0.7) {
                        DispatchQueue.main.async {
                            self.parent.onMediaSelected(.image(data))
                        }
                    }
                }
            } 
            // 2. Έλεγχος αν είναι Βίντεο
            else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    guard let localURL = url else { return }
                    
                    // Επειδή το αρχείο είναι προσωρινό, το αντιγράφουμε σε ασφαλές σημείο στην εφαρμογή
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let targetURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                    
                    try? FileManager.default.copyItem(at: localURL, to: targetURL)
                    
                    DispatchQueue.main.async {
                        self.parent.onMediaSelected(.video(targetURL))
                    }
                }
            }
        }
    }
}