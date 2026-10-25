import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignInSwift
import GoogleSignIn

struct SignInView: View {
    var namespace: Namespace.ID
    var dismiss: () -> Void
    var onSignUp: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState public var isTextFieldFocused: Bool

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
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                AuthTopBar(namespace: namespace, onBack: closeKeyboardAndDismiss)

                AuthHeading(eyebrow: "ΚΑΛΩΣ ΗΡΘΕΣ ΞΑΝΑ", title: "Η ομάδα σου\nείναι εδώ.", subtitle: "Συνδέσου για να συνεχίσεις την ημέρα σου μαζί της.")

                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 18) {
                        AuthField("Email", symbol: "envelope") {
                            TextField("email@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .focused($isTextFieldFocused)
                        }
                        AuthField("Κωδικός πρόσβασης", symbol: "lock") {
                            SecureField("Ο κωδικός σου", text: $password)
                                .textContentType(.password)
                                .focused($isTextFieldFocused)
                        }
                    }

                    if let error = errorMessage {
                        AuthErrorMessage(message: error)
                    }

                    Button(action: submit) {
                        HStack {
                            Text("Σύνδεση")
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StorePrimaryButtonStyle())
                    .disabled(!isFormValid)
                }
                .padding(22)
                .storeCard(radius: 26)

                if let onSignUp {
                    VStack(spacing: 6) {
                        Text("Δεν έχεις λογαριασμό;")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Δημιουργία λογαριασμού") {
                            isTextFieldFocused = false
                            onSignUp()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(minHeight: 44)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func submit() {
        if !isFormValid {
            errorMessage = "Συμπλήρωσε όλα τα πεδία."
        } else if !isEmailValid {
            errorMessage = "Το email πρέπει να έχει τη μορφή email@domain.com."
        } else {
            errorMessage = nil
            authViewModel.signIn(email: email, password: password) { error in
                if let error = error {
                    self.errorMessage = error
                }
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    @Namespace static var ns
    static var previews: some View {
        ZStack {
            AnimatedBlobBackground()
            SignInView(namespace: ns, dismiss: {})
        }
    }
}
