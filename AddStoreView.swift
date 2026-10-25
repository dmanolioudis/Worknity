import SwiftUI

struct AddStoreView: View {
    @Binding var storeName: String
    var onCreated: ((Store) -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    AccountPageBanner(
                        title: "Νέο κατάστημα",
                        subtitle: "Δημιούργησε τον κοινό χώρο της ομάδας σου.",
                        symbol: "building.2.crop.circle"
                    )
                    StoreDetails(storeName: storeName, onCreated: onCreated)
                }
                .padding(20)
            }
            .background { StoreBackdrop() }
            .navigationTitle("Νέο κατάστημα")
            .navigationBarTitleDisplayMode(.inline)
            .tint(StoreDesign.ink)
        }
    }
}

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

#Preview {
    AddStoreView(storeName: .constant(""))
}
