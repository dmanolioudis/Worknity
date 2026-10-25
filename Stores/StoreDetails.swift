import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StoreDetails: View {
    @State var storeName: String
    var onCreated: ((Store) -> Void)? = nil
    @State private var storeAddress = ""
    @State private var storePhone = ""
    @State private var isSaving = false
    @State private var memberEmail = ""
    @State private var isLookingUpMember = false
    @State private var memberError: String?
    @State private var selectedMembers: [DraftMember] = []

    private struct DraftMember: Identifiable {
        let id: String
        let name: String
        let email: String
        let photoURL: String?
    }
    @State private var errorMessage: String?
    // Retain the document ID across retries after an uncertain network response.
    @State private var pendingDocumentID: String?
    @Environment(\.dismiss) private var dismiss

    private var cleanName: String { storeName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cleanAddress: String { storeAddress.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cleanPhone: String { storePhone.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool {
        !cleanName.isEmpty && cleanName.count <= 100 &&
        !cleanAddress.isEmpty && cleanAddress.count <= 300 &&
        !cleanPhone.isEmpty && cleanPhone.count <= 40
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Στοιχεία καταστήματος").font(.headline)
            field("Όνομα καταστήματος", text: $storeName)
            field("Διεύθυνση καταστήματος", text: $storeAddress)
            field("Τηλέφωνο καταστήματος", text: $storePhone, phone: true)
            Text("Θα είσαι manager του καταστήματος. Τα άτομα που προσθέτεις εδώ θα συμμετέχουν ως μέλη.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            memberSelection
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
            Button(action: saveStore) {
                HStack {
                    if isSaving { ProgressView().tint(StoreDesign.actionLabel) }
                    Text("Δημιουργία καταστήματος")
                    Spacer()
                    Image(systemName: "plus")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StorePrimaryButtonStyle())
            .disabled(!isValid || isSaving || isLookingUpMember)
        }
        .padding(20)
        .storeCard()
        .interactiveDismissDisabled(isSaving)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Ακύρωση") { dismiss() }.disabled(isSaving)
            }
        }
    }

    private var memberSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle().fill(StoreDesign.line).frame(height: 1)
            HStack {
                Label("Προσθήκη μελών", systemImage: "person.badge.plus")
                    .font(.headline)
                Spacer()
                Text("Προαιρετικό").font(.caption).foregroundStyle(.secondary)
            }
            Text("Πρόσθεσε άτομα με το email του λογαριασμού τους. Θα αποκτήσουν πρόσβαση όταν δημιουργηθεί το κατάστημα.")
                .font(.footnote).foregroundStyle(.secondary)
            TextField("Email χρήστη", text: $memberEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .storeInput()
                .disabled(isSaving || isLookingUpMember)
                .onSubmit { lookupMember() }
            Button(action: lookupMember) {
                HStack(spacing: 8) {
                    if isLookingUpMember { ProgressView() }
                    Label("Προσθήκη στη λίστα", systemImage: "plus")
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(isSaving || isLookingUpMember || memberEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let memberError {
                Text(memberError).font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(selectedMembers) { member in
                HStack(spacing: 12) {
                    UserProfileImageView(urlString: member.photoURL, size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.name).font(.subheadline.weight(.semibold))
                        Text(member.email).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        selectedMembers.removeAll { $0.id == member.id }
                    } label: {
                        Image(systemName: "minus.circle")
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .accessibilityLabel("Αφαίρεση από τη λίστα")
                }
            }
        }
    }

    private func lookupMember() {
        let email = memberEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !isSaving, !isLookingUpMember, !email.isEmpty else { return }
        guard email.contains("@"), !email.contains(" ") else {
            memberError = AppL10n.text("Το email πρέπει να έχει τη μορφή email@domain.com.")
            return
        }
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        isLookingUpMember = true
        memberError = nil
        Firestore.firestore().collection("users").whereField("email", isEqualTo: email).limit(to: 2)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLookingUpMember = false
                    if let error { memberError = error.localizedDescription; return }
                    guard let documents = snapshot?.documents, let document = documents.first else {
                        memberError = AppL10n.text("Δεν βρέθηκε χρήστης με αυτό το email.")
                        return
                    }
                    guard documents.count == 1 else {
                        memberError = AppL10n.text("Δεν ήταν δυνατή η ταυτοποίηση του λογαριασμού.")
                        return
                    }
                    guard document.documentID != currentUID else {
                        memberError = AppL10n.text("Συμμετέχεις ήδη ως manager του καταστήματος.")
                        return
                    }
                    guard !selectedMembers.contains(where: { $0.id == document.documentID }) else {
                        memberError = AppL10n.text("Το άτομο υπάρχει ήδη στη λίστα.")
                        return
                    }
                    let data = document.data()
                    selectedMembers.append(DraftMember(id: document.documentID,
                        name: data["fullName"] as? String ?? AppL10n.text("Μέλος"),
                        email: data["email"] as? String ?? email,
                        photoURL: data["photoURL"] as? String))
                    memberEmail = ""
                }
            }
    }

    private func field(_ title: LocalizedStringKey, text: Binding<String>, phone: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium))
            TextField(title, text: text)
                .keyboardType(phone ? .phonePad : .default)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .storeInput()
                .disabled(isSaving)
        }
    }

    private func saveStore() {
        guard isValid, !isSaving, !isLookingUpMember else { return }
        guard let user = Auth.auth().currentUser else {
            errorMessage = AppL10n.text("Χρειάζεται σύνδεση για να δημιουργήσεις κατάστημα.")
            return
        }
        hideKeyboard()
        isSaving = true
        errorMessage = nil
        let name = cleanName, address = cleanAddress, phone = cleanPhone
        let participants = Array(Set(selectedMembers.map(\.id)).union([user.uid])).sorted()
        let db = Firestore.firestore()
        let reference = pendingDocumentID.map { db.collection("stores").document($0) } ?? db.collection("stores").document()
        pendingDocumentID = reference.documentID

        // Preserve the existing duplicate-address/phone check.
        db.collection("stores")
            .whereField("address", isEqualTo: address)
            .whereField("phone", isEqualTo: phone)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error {
                        errorMessage = error.localizedDescription
                        isSaving = false
                        return
                    }
                    if snapshot?.documents.contains(where: { $0.documentID != reference.documentID }) == true {
                        errorMessage = AppL10n.text("Υπάρχει ήδη κατάστημα με την ίδια διεύθυνση και τηλέφωνο.")
                        isSaving = false
                        return
                    }
                    let data: [String: Any] = [
                        "name": name, "address": address, "phone": phone,
                        "manager": user.uid, "managers": [user.uid], "participants": participants,
                        "managerPermissions": [user.uid: StorePermission.allCases.map(\.rawValue)]
                    ]
                    db.runTransaction({ transaction, errorPointer -> Any? in
                        do {
                            let existing = try transaction.getDocument(reference)
                            if let existingData = existing.data() {
                                // A previous attempt may have succeeded before its response was lost.
                                // Never overwrite members or permissions on a retry.
                                return existingData
                            }
                            transaction.setData(data, forDocument: reference)
                            return data
                        } catch {
                            errorPointer?.pointee = error as NSError
                            return nil
                        }
                    }) { result, error in
                        DispatchQueue.main.async {
                            isSaving = false
                            if let error { errorMessage = error.localizedDescription; return }
                            guard let saved = result as? [String: Any] else { return }
                            let store = Store(id: reference.documentID,
                                              name: saved["name"] as? String ?? name,
                                              address: saved["address"] as? String ?? address,
                                              phone: saved["phone"] as? String ?? phone,
                                              manager: saved["manager"] as? String ?? user.uid,
                                              participants: saved["participants"] as? [String] ?? [user.uid])
                            onCreated?(store)
                            dismiss()
                        }
                    }
                }
            }
    }
}

#Preview {
    NavigationStack { StoreDetails(storeName: "Example Store").padding() }
}
