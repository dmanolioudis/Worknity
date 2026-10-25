//
//  MediaDetailView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//


//
//  MediaDetailView.swift
//  Worknity
//

import SwiftUI
import AVKit
import Photos
import QuickLook

struct MediaDetailView: View {
    let post: StorePost
    @Environment(\.dismiss) var dismiss
    
    @State private var isDownloading = false
    @State private var statusMessage: String? = nil
    
    var body: some View {
        if post.mediaType == .image {
            PhotoViewer(
                url: post.mediaURL.flatMap { URL(string: $0) },
                title: post.authorName,
                subtitle: post.timestamp.formatted(date: .abbreviated, time: .shortened),
                isSaving: isDownloading,
                statusMessage: statusMessage,
                onSave: downloadToGallery
            )
        } else {
            videoContent
        }
    }

    private var videoContent: some View {
        VideoViewer(
            url: post.mediaURL.flatMap { URL(string: $0) },
            title: post.authorName,
            subtitle: post.timestamp.formatted(date: .abbreviated, time: .shortened),
            isSaving: isDownloading,
            statusMessage: statusMessage,
            onSave: downloadToGallery
        )
    }

    private func downloadToGallery() {
        guard let urlStr = post.mediaURL, let url = URL(string: urlStr) else { return }
        isDownloading = true

        if post.mediaType == .image {
            PhotoLibrarySaver.saveImage(from: url) { result in
                switch result {
                case .success:
                    showToast(msg: "Αποθηκεύτηκε στη Συλλογή Φωτογραφιών!")
                case .failure(let error):
                    showToast(msg: error.localizedDescription)
                }
            }
            return
        }

        guard post.mediaType == .video else {
            showToast(msg: "Αυτός ο τύπος αρχείου δεν αποθηκεύεται στη Συλλογή.")
            return
        }

        PhotoLibrarySaver.saveVideo(from: url) { result in
            switch result {
            case .success:
                showToast(msg: "Αποθηκεύτηκε στη Συλλογή Φωτογραφιών!")
            case .failure(let error):
                showToast(msg: error.localizedDescription)
            }
        }
    }
    
    private func showToast(msg: String) {
        DispatchQueue.main.async {
            self.isDownloading = false
            withAnimation { self.statusMessage = msg }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { self.statusMessage = nil }
            }
        }
    }
}

// --- QuickLook Bridge για SwiftUI (Κοινόχρηστο Component) ---
struct QuickLookPreviewWrapper: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let qlController = QLPreviewController()
        qlController.dataSource = context.coordinator
        return UINavigationController(rootViewController: qlController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(url: url) }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as NSURL
        }
    }
}
