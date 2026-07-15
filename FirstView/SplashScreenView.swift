//
//  SplashScreenView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 6/6/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            RootView()
        } else {
            VStack {
                
                Spacer()
                
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
                
                Spacer()
                
                Text ("Work United ")
                    .font(.custom("Comic Neue", size: 20))
                Text ("Stay Connected ")
                    .font(.custom("Comic Neue", size: 20))
                    
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
           // .background(Color.primary)
            .ignoresSafeArea()
            .onAppear {
                // καθυστέρηση 2 δευτερόλεπτα
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
#Preview {
    SplashScreenView()
}

