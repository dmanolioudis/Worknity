import SwiftUI

/// Stable, proportional paths keep the circles moving smoothly across screen sizes.
struct AnimatedBlobBackground: View {
    @State private var move = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let origins: [UnitPoint] = [
        .init(x: 0.05, y: 0.12), .init(x: 0.85, y: 0.1),
        .init(x: 0.1, y: 0.62), .init(x: 0.95, y: 0.8),
        .init(x: 0.55, y: 0.42), .init(x: 0.35, y: 1.0)
    ]
    private let destinations: [UnitPoint] = [
        .init(x: 0.7, y: 0.28), .init(x: 0.4, y: 0.02),
        .init(x: 0.5, y: 0.88), .init(x: 0.65, y: 0.5),
        .init(x: 0.05, y: 0.32), .init(x: 0.9, y: 0.95)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                StoreDesign.canvas
                ForEach(origins.indices, id: \.self) { index in
                    let point = move && !reduceMotion ? destinations[index] : origins[index]
                    let diameter = min(geometry.size.width * 0.8, 420)
                    Circle()
                        .fill(LinearGradient(colors: [StoreDesign.accent, StoreDesign.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: diameter, height: diameter)
                        .blur(radius: 55)
                        .opacity(colorScheme == .dark ? 0.16 : 0.28)
                        .position(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 10 + Double(index) * 1.5).repeatForever(autoreverses: true), value: move)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { move = true }
    }
}

struct WelcomeView: View {
    var startupNamespace: Namespace.ID? = nil
    @Namespace private var localWordmarkNamespace

    private var logoAnimation: Namespace.ID {
        startupNamespace ?? localWordmarkNamespace
    }
    @State private var currentScreen: Screen? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Screen {
        case signIn, signUp
    }

    var body: some View {
        ZStack {
            AnimatedBlobBackground()

            switch currentScreen {
            case .signIn:
                SignInView(namespace: logoAnimation, dismiss: { currentScreen = nil }, onSignUp: { currentScreen = .signUp })
                    .transition(.opacity)
            case .signUp:
                SignUpView(namespace: logoAnimation, dismiss: { currentScreen = nil }, onSignIn: { currentScreen = .signIn })
                    .transition(.opacity)
            case .none:
                welcomeContent
                    .transition(.opacity)
            }
        }
        .tint(StoreDesign.ink)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: currentScreen)
    }

    private var welcomeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    AuthWordmark(namespace: logoAnimation)
                    Spacer(minLength: 0)
                }
                .padding(.top, 12)

                AuthHeading(
                    eyebrow: AppBrand.slogan.uppercased(),
                    title: "Μια ομάδα.\nΌλα μαζί.",
                    subtitle: "Ο κοινός σας χώρος για επικοινωνία, ενημέρωση και μια καλύτερα οργανωμένη ημέρα."
                )
                VStack(spacing: 24) {
                    WelcomeTeamCard()
                    welcomeActions
                }
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private var welcomeActions: some View {
        VStack(spacing: 10) {
            Button { currentScreen = .signIn } label: {
                HStack {
                    Text("Σύνδεση")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StorePrimaryButtonStyle())

            Button { currentScreen = .signUp } label: {
                Text("Δημιουργία λογαριασμού").frame(maxWidth: .infinity)
            }
            .buttonStyle(AuthSecondaryButtonStyle())
        }
    }
}

#Preview {
    WelcomeView().environmentObject(AuthViewModel())
}
