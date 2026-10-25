import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage?
    @State private var showProfile = false
    @State private var showGeneralSettings = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AccountPageBanner(title: "Ρυθμίσεις", subtitle: "Ο λογαριασμός και οι προτιμήσεις σου.", symbol: "slider.horizontal.3")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 24) {
                        Button { showProfile = true } label: {
                            VStack(alignment: .leading, spacing: 18) {
                                let profileLayout = dynamicTypeSize.isAccessibilitySize
                                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                                    : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
                                profileLayout {
                                    profileAvatar
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(fullName.isEmpty ? AppL10n.text("Το προφίλ σου") : fullName)
                                            .font(.title3.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        if !email.isEmpty {
                                            Text(email)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .textSelection(.disabled)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                                }
                                Rectangle().fill(StoreDesign.line).frame(height: 1)
                                HStack {
                                    Label("Επεξεργασία προφίλ", systemImage: "pencil")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(StoreDesign.ink)
                            }
                            .padding(20)
                            .storeCard()
                            .contentShape(RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 10) {
                            settingsSectionTitle("Προτιμήσεις & δραστηριότητα")
                            VStack(spacing: 0) {
                                menuItem(icon: "gearshape", text: "Γενικές ρυθμίσεις") { showGeneralSettings = true }
                                settingsDivider
                                menuItem(icon: "bell", text: "Ειδοποιήσεις") {}
                                settingsDivider
                                menuItem(icon: "doc.text", text: "Ιστορικό συναλλαγών") {}
                            }
                            .storeCard()
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            settingsSectionTitle("Βοήθεια & πληροφορίες")
                            VStack(spacing: 0) {
                                menuItem(icon: "questionmark.circle", text: "Συχνές ερωτήσεις") {}
                                settingsDivider
                                menuItem(icon: "info.circle", text: "Σχετικά με την εφαρμογή") {}
                            }
                            .storeCard()
                        }

                        Button { authViewModel.signOut() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Αποσύνδεση").font(.subheadline.weight(.semibold))
                                Spacer()
                            }
                            .foregroundStyle(.red)
                            .padding(18)
                            .frame(minHeight: 54)
                            .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                            .contentShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .background { StoreBackdrop() }
            .tint(StoreDesign.ink)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showProfile) { ProfileEditView() }
            .navigationDestination(isPresented: $showGeneralSettings) { GeneralSettingsView() }
            .onAppear { fetchUserData() }
        }
    }

    private var profileAvatar: some View {
        Group {
            if let image = profileImage {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().scaledToFit()
                    .foregroundStyle(StoreDesign.ink)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    private var settingsDivider: some View {
        Rectangle().fill(StoreDesign.line).frame(height: 1).padding(.leading, 66)
    }

    private func settingsSectionTitle(_ title: String) -> some View {
        Text(LocalizedStringKey(title))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }

    func menuItem(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(StoreDesign.ink)
                    .frame(width: 34, height: 34)
                    .background(StoreDesign.softAccent, in: RoundedRectangle(cornerRadius: 11))
                Text(LocalizedStringKey(text))
                    .foregroundStyle(.primary)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Firebase Fetch
    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }

        Firestore.firestore().collection("users")
            .whereField("uid", isEqualTo: user.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching user: \(error)")
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("User document not found")
                    return
                }

                let data = document.data()
                self.fullName = data["fullName"] as? String ?? ""
                self.email = data["email"] as? String ?? ""
                if let urlStr = data["photoURL"] as? String, let url = URL(string: urlStr) {
                    downloadImage(from: url) { image in
                        DispatchQueue.main.async {
                            self.profileImage = image
                        }
                    }
                }
            }
    }

    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}

struct SettingsViewPreview: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        SettingsView()
            .environmentObject(authViewModel)
    }
}

#Preview {
    SettingsViewPreview()
}
