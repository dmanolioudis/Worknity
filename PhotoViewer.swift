import SwiftUI
import UIKit

/// Shared photo presentation for feed posts and conversations.
struct PhotoViewer: View {
    let url: URL?
    var title = AppL10n.text("Φωτογραφία")
    var subtitle: String? = nil
    var isSaving = false
    var statusMessage: String? = nil
    var onSave: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var retryID = UUID()
    @State private var photo: UIImage?
    @State private var failedToLoad = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Κλείσιμο φωτογραφίας")

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let onSave {
                    Button(action: onSave) {
                        ZStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 19, weight: .medium))
                            }
                        }
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.08), in: Circle())
                    }
                    .disabled(isSaving)
                    .accessibilityLabel("Αποθήκευση στη Συλλογή Φωτογραφιών")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Group {
                if let photo {
                    ZoomablePhoto(image: photo, onDismiss: { dismiss() })
                } else if failedToLoad {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.exclamationmark").font(.largeTitle)
                        Text("Η φωτογραφία δεν φορτώθηκε.").font(.subheadline)
                        Button("Δοκιμή ξανά") { retryID = UUID() }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .clipped()
            .task(id: retryID) {
                failedToLoad = false
                guard let url else { failedToLoad = true; return }
                do {
                    let loaded = try await MediaPreviewCache.shared.load(url)
                    guard !Task.isCancelled else { return }
                    photo = loaded
                } catch {
                    guard !Task.isCancelled else { return }
                    failedToLoad = true
                }
            }

            VStack(spacing: 12) {
                if let statusMessage {
                    Text(LocalizedStringKey(statusMessage))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.updatesFrequently)
                }
                Label("Pinch για ζουμ · Σύρε για μετακίνηση", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .background {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.12, blue: 0.11), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}

/// Native zooming keeps the pinch focus and constrains panning to the image edges.
private struct ZoomablePhoto: UIViewRepresentable {
    let image: UIImage
    let onDismiss: () -> Void

    func makeUIView(context: Context) -> PhotoScrollView {
        PhotoScrollView(image: image, onDismiss: onDismiss)
    }

    func updateUIView(_ view: PhotoScrollView, context: Context) {
        view.onDismiss = onDismiss
        if view.photoView.image !== image {
            view.photoView.image = image
            view.resetLayout()
        }
    }
}

private final class PhotoScrollView: UIScrollView, UIScrollViewDelegate {
    let photoView = UIImageView()
    private var viewportSize: CGSize = .zero
    private var fittingImage = false
    var onDismiss: () -> Void
    private let dismissGestureDelegate = PhotoDismissGestureDelegate()

    init(image: UIImage, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(frame: .zero)
        photoView.image = image
        photoView.contentMode = .scaleAspectFit
        photoView.isAccessibilityElement = true
        photoView.accessibilityLabel = AppL10n.text("Φωτογραφία")
        photoView.accessibilityHint = AppL10n.text("Μεγέθυνση έως τέσσερις φορές με δύο δάχτυλα. Σύρε για μετακίνηση ή κάνε διπλό πάτημα για επαναφορά.")
        addSubview(photoView)
        delegate = self
        minimumZoomScale = 1
        maximumZoomScale = 4
        bounces = false
        bouncesZoom = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        backgroundColor = .clear
        clipsToBounds = true

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(resetZoom))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)

        let dismissPan = UIPanGestureRecognizer(target: self, action: #selector(handleDismissSwipe(_:)))
        dismissPan.maximumNumberOfTouches = 1
        dismissGestureDelegate.scrollView = self
        dismissPan.delegate = dismissGestureDelegate
        addGestureRecognizer(dismissPan)
        panGestureRecognizer.require(toFail: dismissPan)
        photoView.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: AppL10n.text("Μεγέθυνση"), target: self, selector: #selector(performPhotoZoomIn)),
            UIAccessibilityCustomAction(name: AppL10n.text("Επαναφορά μεγέθους"), target: self, selector: #selector(performPhotoZoomReset))
        ]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func resetLayout() {
        viewportSize = .zero
        setZoomScale(1, animated: false)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !fittingImage, bounds.width > 0, bounds.height > 0,
              let image = photoView.image, image.size.width > 0, image.size.height > 0 else { return }
        if viewportSize != bounds.size {
            fittingImage = true
            // Keep the viewed point and magnification across viewport size changes.
            let previousScale = zoomScale
            let center = photoView.convert(CGPoint(x: bounds.midX, y: bounds.midY), from: self)
            let relativeCenter = CGPoint(
                x: photoView.bounds.width > 0 ? center.x / photoView.bounds.width : 0.5,
                y: photoView.bounds.height > 0 ? center.y / photoView.bounds.height : 0.5
            )
            viewportSize = bounds.size
            setZoomScale(1, animated: false)
            let fit = min(bounds.width / image.size.width, bounds.height / image.size.height)
            photoView.frame = CGRect(origin: .zero, size: CGSize(width: image.size.width * fit, height: image.size.height * fit))
            contentSize = photoView.bounds.size
            setZoomScale(previousScale, animated: false)
            centerImage()
            let proposed = CGPoint(
                x: relativeCenter.x * contentSize.width - bounds.width / 2,
                y: relativeCenter.y * contentSize.height - bounds.height / 2
            )
            contentOffset = CGPoint(
                x: min(max(proposed.x, -contentInset.left), max(-contentInset.left, contentSize.width - bounds.width + contentInset.right)),
                y: min(max(proposed.y, -contentInset.top), max(-contentInset.top, contentSize.height - bounds.height + contentInset.bottom))
            )
            fittingImage = false
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { photoView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard !fittingImage else { return }
        centerImage()
    }

    private func centerImage() {
        let horizontal = max(0, (bounds.width - photoView.frame.width) / 2)
        let vertical = max(0, (bounds.height - photoView.frame.height) / 2)
        let insets = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        if contentInset != insets { contentInset = insets }
    }

    @objc private func handleDismissSwipe(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended, zoomScale <= minimumZoomScale + 0.01 else { return }
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        if translation.y > abs(translation.x),
           translation.y > 90 || (translation.y > 20 && velocity.y > 800) {
            onDismiss()
        }
    }

    @objc private func resetZoom() {
        setZoomScale(1, animated: !UIAccessibility.isReduceMotionEnabled)
    }

    @objc private func performPhotoZoomIn() -> Bool {
        setZoomScale(min(zoomScale * 1.5, maximumZoomScale), animated: !UIAccessibility.isReduceMotionEnabled)
        return true
    }

    @objc private func performPhotoZoomReset() -> Bool {
        resetZoom()
        return true
    }
}

private final class PhotoDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var scrollView: UIScrollView?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView,
              scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: scrollView)
        return velocity.y > 0 && velocity.y > abs(velocity.x)
    }
}
