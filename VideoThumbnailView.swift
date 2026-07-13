//
//  VideoThumbnailView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 9/7/26.
//

//
//  VideoThumbnailView.swift
//  Worknity
//

import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnailImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped() // Εμποδίζει το image να βγει εκτός ορίων
            } else {
                ZStack {
                    Color.gray.opacity(0.1)
                    if isLoading {
                        ProgressView().tint(.secondary)
                    } else {
                        Image(systemName: "video.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            }
            
            // Play Button Overlay
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.85))
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        guard thumbnailImage == nil else { return }
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.5, preferredTimescale: 60) // frame στο μισό δευτερόλεπτο
            
            do {
                let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: imageRef)
                
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 0.2)) {
                        self.thumbnailImage = uiImage
                        self.isLoading = false
                    }
                }
            } catch {
                print("Αποτυχία δημιουργίας thumbnail βίντεο: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
