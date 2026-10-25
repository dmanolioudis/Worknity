import SwiftUI

enum AppBrand {
    static let slogan = "Work United. Stay Connected."
}

struct AuthWordmark: View {
    let namespace: Namespace.ID
    var prominent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            wordmark
        } else {
            wordmark.matchedGeometryEffect(id: "logo", in: namespace)
        }
    }

    private var wordmark: some View {
        Text("Worknity")
            .font(.system(prominent ? .largeTitle : .title, design: .rounded).weight(.bold))
            .tracking(-1)
            .foregroundStyle(.primary)
            .lineLimit(1)
            // Keep the full text at its intrinsic width while matched geometry
            // interpolates the outer frame between the intro and header sizes.
            .fixedSize(horizontal: true, vertical: true)
    }
}

struct AuthTopBar: View {
    let namespace: Namespace.ID
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(StoreDesign.surface, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(StoreDesign.line))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Πίσω στην αρχική")
            Spacer(minLength: 0)
            AuthWordmark(namespace: namespace)
        }
    }
}

struct AuthHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(eyebrow))
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(StoreDesign.ink)
            Text(LocalizedStringKey(title))
                .font(.largeTitle.weight(.bold))
                .tracking(-1)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            Text(LocalizedStringKey(subtitle))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AuthField<Content: View>: View {
    let title: String
    let symbol: String
    private let content: Content

    init(_ title: String, symbol: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(StoreDesign.ink)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                content
                    .font(.body)
                    .foregroundStyle(.primary)
                    .accessibilityLabel(title)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(minHeight: 50)
            .background(StoreDesign.softAccent.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(StoreDesign.line, lineWidth: 1))
        }
    }
}

struct AuthErrorMessage: View {
    let message: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(message)).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.circle")
        }
        .font(.footnote)
        .foregroundStyle(.red)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

struct AuthSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(StoreDesign.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(StoreDesign.line, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// An editorial illustration of the three real areas of a store, without invented activity.
struct WelcomeTeamCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("ΜΑΖΙ, ΚΑΘΕ ΜΕΡΑ")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(StoreDesign.ink)
                Spacer()
                Image(systemName: "person.3.sequence.fill")
                    .foregroundStyle(StoreDesign.ink)
            }
            feature("Τα νέα μας", detail: "Όσα χρειάζεται να γνωρίζει η ομάδα.", symbol: "text.bubble")
            Rectangle().fill(StoreDesign.line).frame(height: 1)
            feature("Οι συζητήσεις μας", detail: "Κοντά, ακόμη κι όταν είμαστε μακριά.", symbol: "bubble.left.and.bubble.right")
            Rectangle().fill(StoreDesign.line).frame(height: 1)
            feature("Το πρόγραμμά μας", detail: "Κάθε βάρδια, στη θέση της.", symbol: "calendar")
        }
        .padding(22)
        .storeCard(radius: 26)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(StoreDesign.softAccent)
                .rotationEffect(.degrees(-3))
                .padding(.horizontal, 4)
        }
    }

    private func feature(_ title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.body.weight(.medium))
                .foregroundStyle(StoreDesign.ink)
                .frame(width: 42, height: 42)
                .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title)).font(.subheadline.weight(.semibold))
                Text(LocalizedStringKey(detail))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
