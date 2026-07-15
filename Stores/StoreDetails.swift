//
//  StoreDetails.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StoreDetails: View {
    @State var storeName: String
    @State private var storeAdress: String = ""
    @State private var storePhone: String = ""
    @FocusState public var isTextFieldFocused: Bool
    
    @State private var showAddMembers = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var storeDocumentID: String? = nil
    
    var body: some View {
        VStack{
            Text("Store Details")
                .font(.title2)
                .padding(.top)
            
            Spacer()
            
            Text(storeName)
                .padding(.horizontal)
                .frame(width:250,height: 50)
                .cornerRadius(12)
                .font(.title.bold())
            Spacer()
            
            TextField("Store Adress", text: $storeAdress)
                .autocorrectionDisabled()
                .autocapitalization(.words)
                .padding(.horizontal)
                .frame(width:250,height: 50)
                .background(.thinMaterial)
                .cornerRadius(12)
                .focused($isTextFieldFocused)
            
            TextField("Store Phone", text: $storePhone)
                .keyboardType(.phonePad)
                .padding(.horizontal)
                .frame(width:250,height: 50)
                .background(.thinMaterial)
                .cornerRadius(12)
                .focused($isTextFieldFocused)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Button {
                saveStore()
            } label: {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.title2.bold())
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                    .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: 300, maxHeight: 300)
        .background(.thinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 40)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .overlay {
            if isSaving {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(1.5)
            }
        }
    }
    
    func saveStore() {
        isSaving = true
        errorMessage = nil
        
        // Check for existing store with same address and phone
        Firestore.firestore().collection("stores")
            .whereField("address", isEqualTo: storeAdress)
            .whereField("phone", isEqualTo: storePhone)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    errorMessage = ": \(error.localizedDescription)"
                    isSaving = false
                    return
                }
                
                if let snapshot = snapshot, !snapshot.isEmpty {
                    errorMessage = "A store already exists with the same address and phone number."
                    isSaving = false
                    return
                }
                
                // No duplicate found, proceed to save
                guard let user = Auth.auth().currentUser else {
                    errorMessage = "Not signed in."
                    isSaving = false
                    return
                }
                
                let newStore = ["name": storeName, "address": storeAdress, "phone": storePhone, "manager": user.uid]
                let storeRef = Firestore.firestore().collection("stores").document() // create a new doc ref
                storeRef.setData(newStore) { error in
                    if let error = error {
                        errorMessage = ": \(error.localizedDescription)"
                        isSaving = false
                    } else {
                        storeDocumentID = storeRef.documentID
                        showAddMembers = true
                        isSaving = false
                    }
                }
            }
    }
}

#Preview {
    StoreDetails(storeName: "Example Store")
}
