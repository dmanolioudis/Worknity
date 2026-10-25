import SwiftUI
import AVKit

/// One video presentation for the feed and conversations, with native playback controls.
struct VideoViewer: View {
    let url: URL?
    var title = AppL10n.text("Βίντεο")
    var subtitle: String? = nil
    var autoplay = false
    var isSaving = false
    var statusMessage: String? = nil
    var onSave: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var player: AVPlayer?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button {
                    player?.pause()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .accessibilityLabel("Κλείσιμο βίντεο")

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
                if let player {
                    VideoPlayer(player: player)
                } else if url == nil {
                    Label("Το βίντεο δεν είναι διαθέσιμο", systemImage: "video.slash")
                } else {
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .clipped()

            VStack(spacing: 12) {
                if let statusMessage {
                    Text(LocalizedStringKey(statusMessage))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                Label("Βίντεο", systemImage: "play.rectangle")
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let movement = value.translation
                    guard movement.height > abs(movement.width),
                          movement.height > 90 || (movement.height > 30 && value.predictedEndTranslation.height > 240) else { return }
                    player?.pause()
                    dismiss()
                }
        )
        .task(id: url) {
            player?.pause()
            guard let url else { player = nil; return }
            let newPlayer = AVPlayer(url: url)
            player = newPlayer
            if autoplay { newPlayer.play() }
        }
        .onDisappear { player?.pause() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { player?.pause() }
        }
    }
}
