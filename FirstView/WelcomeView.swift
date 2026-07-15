//
//  WelcomeView.swift
//  Worknity
//
//  Created by Dee Manolioudis on 3/6/25.
//

import SwiftUI

struct AnimatedBlobBackground: View {
    @State private var move = false
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")

    var body: some View {
        ZStack {
            ForEach(0..<10) { i in
                Circle()
                    .fill(LinearGradient(colors: [mainColor, secondaryColor], startPoint: .top, endPoint: .bottom))
                    .frame(width: 200, height: 200)
                    .position(x: move ? CGFloat.random(in: 0...400) : CGFloat.random(in: 0...400),
                              y: move ? CGFloat.random(in: 0...800) : CGFloat.random(in: 0...800))
                    .blur(radius: 40)
                    .opacity(0.3)
                    .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: move)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            move.toggle()
        }
    }
}


struct WelcomeView: View {
    @Namespace var logoAnimation
    @State private var currentScreen: Screen? = nil
    
    enum Screen {
        case signIn, signUp
    }

    var body: some View {
        ZStack {
            AnimatedBlobBackground()

            switch currentScreen {
            case .signIn:
                SignInView(namespace: logoAnimation) {
                    withAnimation {
                        currentScreen = nil
                    }
                }
                .transition(.opacity)

            case .signUp:
                SignUpView(namespace: logoAnimation) {
                    withAnimation {
                        currentScreen = nil
                    }
                }
                .transition(.opacity)

            case .none:
                VStack {
                    Spacer()

                    Text("Worknity")
                        .font(.custom("Grand Hotel", size: 66))
                        .matchedGeometryEffect(id: "logo", in: logoAnimation)
                        .multilineTextAlignment(.center)
                        .padding(.top, 50)
                        .offset(y: currentScreen != nil ? -250 : 0)
                        .animation(.easeInOut(duration: 0.8), value: currentScreen)
                    

                    Button("Sign In") {
                        withAnimation(.spring()) {
                            currentScreen = .signIn
                        }
                    }
                    .font(.title2)
                    .padding()
                    .foregroundColor(.primary)
                    .frame(width: 200, height: 50)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Spacer()
                    
                    Text("Don't have an account?")
                                            
                                            
                    Button("Sign Up") {
                        withAnimation(.spring()) {
                            currentScreen = .signUp
                        }
                    }
                    .foregroundColor(Color(hex: "#DFD0B8"))

                    Spacer()
                }
                .padding()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentScreen)
    }
}


#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())

}
