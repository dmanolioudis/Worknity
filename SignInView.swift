import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignInSwift
import GoogleSignIn

struct SignInView: View {
    var namespace: Namespace.ID
    var dismiss: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState public var isTextFieldFocused: Bool
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")


    
    var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty
    }

    var isEmailValid: Bool {
        let emailRegEx = #"^\S+@\S+\.\S+$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    
    func closeKeyboardAndDismiss() {
        isTextFieldFocused = false

        // Καθυστέρηση 0.3s για να κλείσει πρώτα το πληκτρολόγιο
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Worknity")
                .font(.custom("Grand Hotel", size: 66))
                .matchedGeometryEffect(id: "logo", in: namespace)
                .padding(.top, 60)
                .onTapGesture {
                    closeKeyboardAndDismiss()
                }

            Spacer()

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
                .frame(width: 350, height: 50)
                .background(.thinMaterial)
                .cornerRadius(12)
                .focused($isTextFieldFocused)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding(.horizontal)
                .frame(width: 350, height: 50)
                .background(.thinMaterial)
                .cornerRadius(12)
                .focused($isTextFieldFocused)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Login") {
                if !isFormValid {
                    errorMessage = "Please fill in all fields"
                } else if !isEmailValid {
                    errorMessage = "Email should be in the format: email@domain.com"
                } else {
                    errorMessage = nil
                    authViewModel.signIn(email: email, password: password) { error in
                        if let error = error {
                            self.errorMessage = error
                        }
                    }
                }
            }

            .padding()
            .frame(width: 200)
            .background(isFormValid ? mainColor.opacity(1.0) : mainColor.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.top, 20)
            .opacity(isFormValid ? 1.0 : 0.5)
            .disabled(!isFormValid)

            Spacer()

            Button("Back") {
                withAnimation(.spring()) {
                    dismiss()
                }
            }
            .foregroundColor(.gray)

            Spacer()
        }
        .onTapGesture {
            isTextFieldFocused = false // Dismiss keyboard
        }
        
        .padding()
    }
}

// ✅ Preview
struct SignInView_Previews: PreviewProvider {
    @Namespace static var ns
    static var previews: some View {
        SignInView(namespace: ns, dismiss: {})
    }
}

