import SwiftUI
import AVFoundation

/// Bounded, shared cache survives lazy rows leaving the screen.
/// URL keys keep new uploads separate from previously displayed media.
@MainActor
final class MediaPreviewCache {
    static let shared = MediaPreviewCache()
    private let images = NSCache<NSString, UIImage>()
    private var pending: [String: Task<UIImage, Error>] = [:]

    private init() {
        images.totalCostLimit = 80 * 1024 * 1024
        images.countLimit = 160
    }

    private func key(for url: URL, video: Bool) -> String {
        (video ? "video:" : "image:") + url.absoluteString
    }

    func cached(_ url: URL, video: Bool = false) -> UIImage? {
        images.object(forKey: key(for: url, video: video) as NSString)
    }

    func load(_ url: URL, video: Bool = false) async throws -> UIImage {
        if let image = cached(url, video: video) { return image }
        let key = key(for: url, video: video)
        if let task = pending[key] { return try await task.value }

        // A row disappearing must not cancel a download shared by other rows.
        let task = Task.detached(priority: .userInitiated) { () throws -> UIImage in
            if video {
                let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 1600, height: 1600)
                let frame = try generator.copyCGImage(at: .zero, actualTime: nil)
                return UIImage(cgImage: frame)
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            return image
        }
        pending[key] = task
        defer { pending[key] = nil }
        let image = try await task.value
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        images.setObject(image, forKey: key as NSString, cost: cost)
        return image
    }
}

@MainActor
struct CachedRemoteImage<Content: View>: View {
    let url: URL?
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        if let url, let image = MediaPreviewCache.shared.cached(url) {
            _phase = State(initialValue: .success(Image(uiImage: image)))
        } else {
            _phase = State(initialValue: .empty)
        }
    }

    init<ImageContent: View, Placeholder: View>(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> ImageContent,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) where Content == _ConditionalContent<ImageContent, Placeholder> {
        self.init(url: url) { phase in
            if let image = phase.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                guard let url else { phase = .empty; return }
                if let image = MediaPreviewCache.shared.cached(url) {
                    phase = .success(Image(uiImage: image))
                    return
                }
                phase = .empty
                do {
                    let image = try await MediaPreviewCache.shared.load(url)
                    guard !Task.isCancelled else { return }
                    phase = .success(Image(uiImage: image))
                } catch {
                    guard !Task.isCancelled else { return }
                    phase = .failure(error)
                }
            }
    }
}
