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

@MainActor
struct VideoThumbnailView: View {
    let videoURL: URL
    var preservesAspectRatio = false
    @State private var thumbnailImage: UIImage? = nil
    @State private var isLoading = false

    init(videoURL: URL, preservesAspectRatio: Bool = false) {
        self.videoURL = videoURL
        self.preservesAspectRatio = preservesAspectRatio
        _thumbnailImage = State(initialValue: MediaPreviewCache.shared.cached(videoURL, video: true))
    }

    var body: some View {
        ZStack {
            if let image = thumbnailImage {
                if preservesAspectRatio {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 480)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
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
        .frame(maxWidth: .infinity)
        .background(StoreDesign.softAccent)
        .clipShape(RoundedRectangle(cornerRadius: preservesAspectRatio ? 18 : 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: preservesAspectRatio ? 18 : 16, style: .continuous))
        .task(id: videoURL) {
            if let image = MediaPreviewCache.shared.cached(videoURL, video: true) {
                thumbnailImage = image
                return
            }
            isLoading = true
            defer { isLoading = false }
            do {
                let image = try await MediaPreviewCache.shared.load(videoURL, video: true)
                guard !Task.isCancelled else { return }
                thumbnailImage = image
            } catch {
                // Keep the playable fallback when a preview cannot be generated.
            }
        }
    }
}
