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
    
    // Advanced Zoom & Pan States
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @State private var isDownloading = false
    @State private var statusMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Group {
                    switch post.mediaType {
                    case .image:
                        if let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .simultaneousGesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    if scale > 1.0 {
                                                        offset = CGSize(
                                                            width: lastOffset.width + value.translation.width,
                                                            height: lastOffset.height + value.translation.height
                                                        )
                                                    }
                                                }
                                                .onEnded { _ in
                                                    lastOffset = offset
                                                }
                                        )
                                        .simultaneousGesture(
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    scale = lastScale * value
                                                }
                                                .onEnded { _ in
                                                    if scale < 1.0 {
                                                        withAnimation(.spring()) {
                                                            scale = 1.0
                                                            offset = .zero
                                                            lastOffset = .zero
                                                        }
                                                    }
                                                    lastScale = scale
                                                }
                                        )
                                } else {
                                    ProgressView().tint(.white)
                                }
                            }
                        }
                        
                    case .video:
                        if let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                            VideoPlayer(player: AVPlayer(url: url))
                                .ignoresSafeArea()
                        }
                        
                    default:
                        EmptyView()
                    }
                }
                
                if let msg = statusMessage {
                    Text(msg)
                        .font(.footnote.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 20)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Κλείσιμο") { dismiss() }.foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: downloadToGallery) {
                        if isDownloading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "square.and.arrow.down").foregroundColor(.white)
                        }
                    }
                    .disabled(isDownloading)
                }
            }
        }
    }
    
    private func downloadToGallery() {
        guard let urlStr = post.mediaURL, let url = URL(string: urlStr) else { return }
        isDownloading = true
        
        URLSession.shared.downloadTask(with: url) { localURL, _, error in
            guard let localURL = localURL else {
                showToast(msg: "Αποτυχία λήψης αρχείου")
                return
            }
            
            let filename = post.fileName ?? url.lastPathComponent
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.copyItem(at: localURL, to: tempURL)
            
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges {
                        if post.mediaType == .image {
                            if let data = try? Data(contentsOf: tempURL), let image = UIImage(data: data) {
                                PHAssetChangeRequest.creationRequestForAsset(from: image)
                            }
                        } else if post.mediaType == .video {
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                        }
                    } completionHandler: { success, _ in
                        showToast(msg: success ? "Αποθηκεύτηκε στη Συλλογή Φωτογραφιών!" : "Σφάλμα αποθήκευσης")
                    }
                } else {
                    showToast(msg: "Δεν επιτράπηκε η πρόσβαση στη Συλλογή")
                }
            }
        }.resume()
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
