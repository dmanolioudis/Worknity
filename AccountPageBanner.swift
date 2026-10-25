import SwiftUI

/// Shared, non-floating introduction for the home and account screens.
struct AccountPageBanner: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WORKNITY")
                        .font(.caption2.weight(.semibold))
                        .tracking(2.5)
                        .foregroundStyle(StoreDesign.ink)
                    Text(LocalizedStringKey(title))
                        .font(.title2.weight(.bold))
                        .tracking(-0.4)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 0)
                StoreIcon(symbol: symbol)
                    .accessibilityHidden(true)
            }
            Text(LocalizedStringKey(subtitle))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .storeCard(radius: 24)
    }
}

#Preview("Account banner · Light") {
    AccountPageBanner(title: "Ο χώρος σου", subtitle: "Η ομάδα, τα νέα και το πρόγραμμά σου. Όλα ξεκινούν εδώ.", symbol: "building.2")
        .padding(20)
        .background { StoreBackdrop() }
        .preferredColorScheme(.light)
}

#Preview("Account banner · Dark") {
    AccountPageBanner(title: "Ρυθμίσεις", subtitle: "Ο λογαριασμός και οι προτιμήσεις σου.", symbol: "slider.horizontal.3")
        .padding(20)
        .background { StoreBackdrop() }
        .preferredColorScheme(.dark)
}

#Preview("Account banner · Large text") {
    AccountPageBanner(title: "Το προφίλ σου", subtitle: "Η φωτογραφία και τα προσωπικά σου στοιχεία.", symbol: "person.crop.circle")
        .padding(20)
        .background { StoreBackdrop() }
        .environment(\.dynamicTypeSize, .accessibility3)
}
