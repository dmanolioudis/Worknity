import SwiftUI
import UIKit

/// Shared visual language for store destinations and their sheets.
/// Semantic surfaces keep the same hierarchy in light and dark appearances.
enum StoreDesign {
    static let accent = Color(hex: "#948979")
    static let ink = accent
    static let secondary = Color(hex: "#DFD0B8")
    static let canvas = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.085, blue: 0.08, alpha: 1)
            : UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1)
    })
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let line = Color.primary.opacity(0.07)
    static let softAccent = accent.opacity(0.12)
    static let messageRadius: CGFloat = 20
    static let composerInset: CGFloat = 8
    static let composerRadius = messageRadius + composerInset
    // Flat, high-contrast actions; glass is reserved for surrounding surfaces.
    static let actionFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.875, green: 0.816, blue: 0.722, alpha: 1)
            : UIColor(red: 0.435, green: 0.396, blue: 0.337, alpha: 1)
    })
    static let actionLabel = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : .white
    })
}

struct StorePageHeader: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStringKey(title))
                    .font(.largeTitle.weight(.bold))
                    .tracking(-0.8)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                Text(LocalizedStringKey(subtitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            StoreIcon(symbol: symbol)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
}

struct StoreIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 21, weight: .medium))
            .foregroundStyle(StoreDesign.ink)
            .frame(width: 48, height: 48)
            .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct StoreEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            StoreIcon(symbol: symbol).accessibilityHidden(true)
            Text(LocalizedStringKey(title)).font(.headline).multilineTextAlignment(.center)
            Text(LocalizedStringKey(message))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .storeCard()
        .padding(.horizontal, 20)
    }
}

struct StorePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(StoreDesign.actionLabel)
            .padding(.horizontal, 18)
            .frame(minHeight: 46)
            .background(StoreDesign.actionFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
    }
}

/// Matching 44-point controls nest inside the composer's eight-point inset.
struct StoreComposerButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(prominent ? StoreDesign.actionLabel : StoreDesign.ink)
            .frame(width: 44, height: 44)
            .background(prominent ? StoreDesign.actionFill : StoreDesign.softAccent,
                        in: RoundedRectangle(cornerRadius: StoreDesign.messageRadius, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

/// Decorative color beneath the material makes translucency visible without animation.
struct StoreBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    var chat = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                StoreDesign.canvas
                RadialGradient(colors: [Color(hex: "#DFD0B8").opacity(colorScheme == .dark ? 0.18 : 0.65), .clear], center: .topLeading, startRadius: 0, endRadius: proxy.size.height * 0.7)
                RadialGradient(colors: [Color(hex: "#9EB5AD").opacity(colorScheme == .dark ? 0.14 : 0.25), .clear], center: .bottomTrailing, startRadius: 0, endRadius: proxy.size.height * 0.65)
                if chat {
                    Canvas { context, size in
                        for x in stride(from: CGFloat(14), to: size.width, by: 28) {
                            for y in stride(from: CGFloat(14), to: size.height, by: 28) {
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(StoreDesign.ink.opacity(0.10)))
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct StoreGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let radius: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Group {
            if reduceTransparency {
                content.background {
                    shape.fill(StoreDesign.surface)
                        .overlay { shape.fill(tint) }
                }
            } else if #available(iOS 26.0, *) {
                content.glassEffect(.clear.tint(tint), in: shape)
            } else {
                content
                    .background(tint, in: shape)
                    .background(.ultraThinMaterial, in: shape)
                    .overlay {
                        shape.strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.08), StoreDesign.line], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        ).allowsHitTesting(false)
                    }
            }
        }
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 5)
    }
}

/// Opaque, matte message bubbles; no blur or glass highlights.
struct StoreBubbleSurface: View {
    var outgoing = false

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: StoreDesign.messageRadius,
            bottomLeadingRadius: outgoing ? StoreDesign.messageRadius : 5,
            bottomTrailingRadius: outgoing ? 5 : StoreDesign.messageRadius,
            topTrailingRadius: StoreDesign.messageRadius
        )
        shape.fill(StoreDesign.surface)
            .overlay {
                shape.fill(outgoing ? StoreDesign.accent.opacity(0.18) : .clear)
            }
            .overlay {
                shape.strokeBorder(StoreDesign.line, lineWidth: 0.7)
            }
    }
}

extension View {
    func storeCard(radius: CGFloat = 22) -> some View {
        background(StoreDesign.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(StoreDesign.line, lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }

    func storeGlass(radius: CGFloat = 22, tint: Color = .clear) -> some View {
        modifier(StoreGlass(radius: radius, tint: tint))
    }

    func storeInput() -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 16))
    }
}
