//
//  AddStoreView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/6/25.
//

import SwiftUI

struct AddStoreView: View {
    @Binding var storeName: String 
    @State private var showDetails = false
    @FocusState public var isTextFieldFocused: Bool
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")
    
    var body: some View {
        if showDetails == false {
            VStack{
                Text("Add Store")
                    .font(.title2)
                    .padding(.top)
                
                Spacer()
                
                TextField("", text: $storeName)
                    .autocorrectionDisabled()
                    .autocapitalization(.words)
                    .padding(.horizontal)
                    .frame(width:250,height: 50)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                
                
                
                
                
                Spacer()
                
            }
            .frame(maxWidth: 300, maxHeight: 200)
            .background(.thinMaterial)
            .cornerRadius(16)
            .padding(.horizontal)
            .padding(.bottom, 40)
            .onTapGesture {
                isTextFieldFocused = false
            }
        }else {
            if showDetails {
                   StoreDetails(storeName: storeName)
                       .transition(.move(edge: .trailing)) // Slide in from right
                       .zIndex(3)
               }
            
        }
        HStack{
            if showDetails {
                Button{
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showDetails = false

                    }
                } label: {
                    Image(systemName:"chevron.left.circle.fill")
                        .resizable()
                        .foregroundColor(mainColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }.padding(.leading,25)
                
                Spacer()
                
                Button{
                   //save store
                } label: {
                    Image(systemName:"checkmark.circle.fill")
                        .resizable()
                        .foregroundColor(mainColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
                .padding(.trailing,25)
             


                
                
            }else{
                Spacer()
                
                Button{
                    isTextFieldFocused = false
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showDetails = true
                    }
                } label: {
                    Image(systemName:"chevron.right.circle.fill")
                        .resizable()
                        .foregroundColor(mainColor)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }.padding(.trailing,25)
                
            }
                
            
        
    }
       
       
        }
    }

func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

#Preview {
    AddStoreView(storeName: .constant("mystore"))
}

