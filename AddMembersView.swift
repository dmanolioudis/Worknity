import SwiftUI

struct AddMembersView: View {
    let storeID: String
    @StateObject private var viewModel = AddMembersViewModel()
    @State private var emailInput: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Προσθήκη Μέλους")
                .font(.title2.bold())
            
            TextField("Email χρήστη", text: $emailInput)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            Button(action: {
                viewModel.addMember(email: emailInput, storeID: storeID) { success in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
                    }
                }
            }) {
                Text("Προσθήκη στη Συνομιλία")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#948979"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 320)
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
