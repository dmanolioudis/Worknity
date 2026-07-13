import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Binding var selectedTab: Tabs
    @Binding var tabBarMode: TabBarMode

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage?
    @State private var showProfile = false
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {

                HStack {
                    Text("Settings")
                        .font(.title2.bold())
                        .padding(.leading, 4)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Profile
                HStack(spacing: 16) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(fullName)
                            .font(.system(size: 18, weight: .semibold))
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                // Menu options
                VStack(alignment: .leading, spacing: 1) {
                    menuItem(icon: "person", text: "My Profile") {
                        showProfile = true
                    }
                    menuItem(icon: "gearshape", text: "Settings") {}
                    menuItem(icon: "bell", text: "Notifications") {}
                    menuItem(icon: "doc.text", text: "Transaction History") {}
                    menuItem(icon: "questionmark.circle", text: "FAQ") {}
                    menuItem(icon: "info.circle", text: "About App") {}
                }
                .cornerRadius(10)
                .padding(.top, 10)

                Spacer()

                // Logout
                Button(action: {
                    try? Auth.auth().signOut()
                    isLoggedIn = false
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                }
                .padding(.bottom, 60)

                NavigationLink(destination: ProfileEditView(), isActive: $showProfile) {
                    EmptyView()
                }
            }
            .onAppear {
                tabBarMode = .root
                fetchUserData()
            }
        }
    }

    func menuItem(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.primary)

                Text(text)
                    .foregroundColor(.primary)
                    .font(.system(size: 16))

                Spacer()
            }
            .padding()
        }
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
    @State private var selectedTab: Tabs = .settings
    @State private var tabBarMode: TabBarMode = .root

    var body: some View {
        SettingsView(
            selectedTab: $selectedTab,
            tabBarMode: $tabBarMode
        )
    }
}

#Preview {
    SettingsViewPreview()
}
