import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @Namespace private var wordmarkNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isActive {
                // The same namespace reaches WelcomeView through RootView, so the
                // wordmark moves from the center of the intro to the welcome header.
                RootView(startupNamespace: wordmarkNamespace)
                    .transition(.opacity)
            } else {
                StartupBrandContent(namespace: wordmarkNamespace)
                    .background { AnimatedBlobBackground() }
                    .transition(.opacity)
                    .task {
                        // A short brand introduction, not a simulated loading operation.
                        do {
                            try await Task.sleep(for: .seconds(2))
                        } catch {
                            return
                        }
                        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.85)) {
                            isActive = true
                        }
                    }
            }
        }
    }
}

/// Only the wordmark and official slogan; there is no separate logo or loading UI.
private struct StartupBrandContent: View {
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 18) {
            AuthWordmark(namespace: namespace, prominent: true)
            Text(AppBrand.slogan)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .tracking(0.4)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StartupBrandPreview: View {
    @Namespace private var namespace

    var body: some View {
        StartupBrandContent(namespace: namespace)
            .background { AnimatedBlobBackground() }
    }
}

#Preview("Startup · Light") {
    StartupBrandPreview().preferredColorScheme(.light)
}

#Preview("Startup · Dark") {
    StartupBrandPreview().preferredColorScheme(.dark)
}

#Preview("Startup · Large text") {
    StartupBrandPreview().environment(\.dynamicTypeSize, .accessibility3)
}
