import SwiftUI

struct AddMembersView: View {
    let storeID: String
    @StateObject private var viewModel = AddMembersViewModel()
    @State private var emailInput: String = ""
    @Environment(\.dismiss) var dismiss
    let mainColor = Color(hex: "#948979")


    var body: some View {
        NavigationStack{
        VStack(spacing: 20) {
            
            
            TextField("Email χρήστη", text: $emailInput)
                .padding(7)
                .background{
                    if #available(iOS 26.0, *){
                        RoundedRectangle(cornerRadius: 20)
                            .glassEffect(.clear.tint(Color.colorBar.opacity(0.4)).interactive(), in: .rect(cornerRadius: 20))
                    }
                    else{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                        
                    }
                }
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
            
            Button("Προσθήκη στην Συνομιλία", action: {
                viewModel.addMember(email: emailInput, storeID: storeID) { success in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
                    }
                }
            })
            .bold()
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background{
                if #available(iOS 26.0, *){
                    RoundedRectangle(cornerRadius: 15)
                        .glassEffect(.clear.tint(mainColor.opacity(0.5)).interactive(), in: .rect(cornerRadius: 15))
                }
                else{
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.ultraThinMaterial)
                    
                }
            }
            
            .padding(.horizontal)
            
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Προσθήκη Μέλους")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
        .frame(width: 320)
        .cornerRadius(20)
        }
    }
}


