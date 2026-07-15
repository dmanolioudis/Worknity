import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignInSwift
import GoogleSignIn

struct Country: Identifiable {
    let id = UUID()
    let name: String
    let prefix: String
    let phoneLength: Int
}

let countries: [Country] = [
    Country(name: "Greece", prefix: "+30", phoneLength: 10),
    Country(name: "USA", prefix: "+1", phoneLength: 10),
    Country(name: "UK", prefix: "+44", phoneLength: 10),
    Country(name: "Germany", prefix: "+49", phoneLength: 11)
]


struct SignUpView: View {
    var namespace: Namespace.ID
    var dismiss: () -> Void
    let mainColor = Color(hex: "#948979")
    let secondaryColor = Color(hex: "#DFD0B8")


    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var dateOfBirth = ""
    @State private var gender: String = ""
    @State private var errorMessage: String?
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @FocusState public var isTextFieldFocused: Bool




    @State private var selectedCountry: Country = countries.first!

    var isPhoneValid: Bool {
        let digitsOnly = phone.filter { $0.isNumber }
        return digitsOnly.count == selectedCountry.phoneLength
    }

    var isFormValid: Bool {
        return !fullName.isEmpty &&
               !username.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !phone.isEmpty &&
               isEmailValid &&
               isPasswordStrong &&
               isPhoneValid
    }

    var isEmailValid: Bool {
        let emailRegEx = #"^\S+@\S+\.\S+$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    var isPasswordStrong: Bool {
        let passwordRegEx = #"^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$&*._-]).{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegEx).evaluate(with: password)
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
            Color.clear
            Text("Worknity")
                .font(.custom("Grand Hotel", size: 66))
                .matchedGeometryEffect(id: "logo", in: namespace)
                .padding(.top,)
                .onTapGesture {
                    closeKeyboardAndDismiss()
                }
            Group {
                Button(action: {
                    showImagePicker = true
                }) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.gray)
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage)
                }
                .padding()

                TextField("Full Name", text: $fullName)
                    .autocapitalization(.words)
                    .padding(.horizontal)
                    .frame(width: 350, height: 50)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)

                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                    .frame(width: 350, height: 50)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                
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
                    .textContentType(.newPassword)
                    .padding(.horizontal)
                    .frame(width: 350, height: 50)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)

                // Country Picker + Phone
                HStack {
                    Menu {
                        ForEach(countries) { country in
                            Button(action: {
                                selectedCountry = country
                            }) {
                                Text("\(country.name) (\(country.prefix))")
                            }
                        }
                    } label: {
                        Text(selectedCountry.prefix)
                            .padding(.horizontal)
                            .frame(height: 50)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .accentColor(mainColor)

                    }
                    .frame(width: 70)

                    TextField("Phone Number", text: $phone)
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                        .frame(height: 50)
                        .background(.thinMaterial)
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                }
                .frame(width: 350)
            }
            
            Spacer()

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Register") {
                if !isFormValid {
                    errorMessage = "Please fill in all fields correctly"
                } else {
                    errorMessage = nil
                    let fullPhone = "\(selectedCountry.prefix)\(phone)"

                    authViewModel.register(
                        fullName: fullName,
                        dateOfBirth: dateOfBirth,
                        gender: gender,
                        username: username,
                        email: email,
                        password: password,
                        phone: fullPhone,
                        image: selectedImage
                    ) { error in
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

            Button("Back") {
                withAnimation(.spring()) {
                    dismiss()
                }
            }
            .foregroundColor(.gray)

            Spacer()
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    
        .padding()
    }
}

struct SignUpView_Previews: PreviewProvider {
    @Namespace static var ns
    static var previews: some View {
        SignUpView(namespace: ns, dismiss: {})
    }
}
