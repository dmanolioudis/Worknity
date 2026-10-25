import SwiftUI

struct AddMembersView: View {
    let storeID: String
    @StateObject private var viewModel = AddMembersViewModel()
    @State private var emailInput: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        StoreIcon(symbol: "person.badge.plus")
                        Text("Η ομάδα μεγαλώνει")
                            .font(.title2.weight(.semibold))
                    }
                    Text("Πρόσθεσε ένα μέλος με το email του λογαριασμού του.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email χρήστη").font(.subheadline.weight(.medium))
                        TextField("Email χρήστη", text: $emailInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .storeInput()
                    }

                    Button {
                        viewModel.addMember(email: emailInput, storeID: storeID) { success in
                            if success {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
                            }
                        }
                    } label: {
                        Label("Προσθήκη στην Συνομιλία", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StorePrimaryButtonStyle())

                    Text(viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(24)
            }
            .background { StoreBackdrop() }
            .tint(StoreDesign.ink)
            .navigationTitle("Προσθήκη Μέλους")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
