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
    var onSignIn: (() -> Void)? = nil

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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                AuthTopBar(namespace: namespace, onBack: closeKeyboardAndDismiss)
                AuthHeading(eyebrow: "ΜΙΑ ΝΕΑ ΑΡΧΗ", title: "Γίνε μέρος\nτης ομάδας.", subtitle: "Δημιούργησε τον λογαριασμό σου και έλα πιο κοντά στους ανθρώπους της δουλειάς σου.")

                VStack(alignment: .leading, spacing: 20) {
                    let photoLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                        : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
                    photoLayout {
                        Button { showImagePicker = true } label: {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let selectedImage {
                                        Image(uiImage: selectedImage).resizable().scaledToFill()
                                    } else {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable().scaledToFit()
                                            .foregroundStyle(StoreDesign.ink)
                                    }
                                }
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(StoreDesign.actionLabel)
                                    .frame(width: 26, height: 26)
                                    .background(StoreDesign.actionFill, in: Circle())
                                    .overlay(Circle().strokeBorder(StoreDesign.surface, lineWidth: 2))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Επιλογή φωτογραφίας προφίλ")

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Το πρόσωπο πίσω από το όνομα")
                                .font(.subheadline.weight(.semibold))
                            Button(selectedImage == nil ? "Προσθήκη φωτογραφίας" : "Αλλαγή φωτογραφίας") { showImagePicker = true }
                                .font(.caption)
                                .foregroundStyle(StoreDesign.ink)
                                .frame(minHeight: 44)
                            Text("Προαιρετικό")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Rectangle().fill(StoreDesign.line).frame(height: 1)

                    AuthField("Ονοματεπώνυμο", symbol: "person") {
                        TextField("Το όνομά σου", text: $fullName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .focused($isTextFieldFocused)
                    }
                    AuthField("Όνομα χρήστη", symbol: "at") {
                        TextField("username", text: $username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isTextFieldFocused)
                    }
                }
                .padding(22)
                .storeCard(radius: 26)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Στοιχεία λογαριασμού")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    AuthField("Email", symbol: "envelope") {
                        TextField("email@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .focused($isTextFieldFocused)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        AuthField("Κωδικός πρόσβασης", symbol: "lock") {
                            SecureField("Δημιούργησε έναν κωδικό", text: $password)
                                .textContentType(.newPassword)
                                .focused($isTextFieldFocused)
                        }
                        Text("Τουλάχιστον 8 χαρακτήρες, ένα κεφαλαίο, ένας αριθμός και ένα από τα σύμβολα !@#$&*._-")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Κινητό τηλέφωνο").font(.subheadline.weight(.medium))
                        let phoneLayout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                            : AnyLayout(HStackLayout(spacing: 10))
                        phoneLayout {
                            Menu {
                                ForEach(countries) { country in
                                    Button { selectedCountry = country } label: {
                                        Text("\(country.name) (\(country.prefix))")
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(selectedCountry.prefix)
                                        .font(.subheadline.weight(.medium))
                                    Image(systemName: "chevron.down").font(.caption2.weight(.semibold))
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 50)
                                .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 15))
                            }
                            .accessibilityLabel("Κωδικός χώρας")
                            .accessibilityValue("\(selectedCountry.name), \(selectedCountry.prefix)")

                            TextField("Αριθμός κινητού", text: $phone)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.numberPad)
                                .focused($isTextFieldFocused)
                                .font(.body)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 13)
                                .frame(minHeight: 50)
                                .background(StoreDesign.softAccent.opacity(0.7), in: RoundedRectangle(cornerRadius: 15))
                                .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(StoreDesign.line, lineWidth: 1))
                                .accessibilityLabel("Αριθμός κινητού")
                        }
                        Text("\(selectedCountry.phoneLength) ψηφία, χωρίς τον κωδικό χώρας.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(22)
                .storeCard(radius: 26)

                if let error = errorMessage {
                    AuthErrorMessage(message: error)
                }

                Button(action: submit) {
                    HStack {
                        Text("Δημιουργία λογαριασμού")
                        Spacer(minLength: 4)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(StorePrimaryButtonStyle())
                .disabled(!isFormValid)

                if let onSignIn {
                    VStack(spacing: 6) {
                        Text("Έχεις ήδη λογαριασμό;")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Σύνδεση") {
                            isTextFieldFocused = false
                            onSignIn()
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func submit() {
        if !isFormValid {
            errorMessage = "Συμπλήρωσε σωστά όλα τα πεδία."
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
}

struct SignUpView_Previews: PreviewProvider {
    @Namespace static var ns
    static var previews: some View {
        ZStack {
            AnimatedBlobBackground()
            SignUpView(namespace: ns, dismiss: {})
        }
    }
}
