import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StoreConversation: Identifiable, Hashable {
    let id: String
    let name: String
    var participantIDs: [String]? = nil
    var groupID: String? { id == "general" ? nil : id }
}

final class StoreConversations: ObservableObject {
    @Published private(set) var groups: [StoreConversation] = []
    @Published private(set) var error: String?
    @Published private(set) var isLoading = true
    private var listener: ListenerRegistration?
    let storeID: String

    init(storeID: String) {
        self.storeID = storeID
        listener = Firestore.firestore().collection("stores").document(storeID).collection("groups")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.error = error?.localizedDescription
                    self?.groups = snapshot?.documents.compactMap { document in
                        guard let name = document.data()["name"] as? String else { return nil }
                        return StoreConversation(id: document.documentID, name: name, participantIDs: ConversationAccess.participants(in: document.data(), key: "participantIDs"))
                    }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } ?? []
                }
            }
    }
    deinit { listener?.remove() }

    static func save(storeID: String, groupID: String?, name: String, participantIDs: Set<String>, completion: @escaping (Error?) -> Void) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uid = Auth.auth().currentUser?.uid, !name.isEmpty, name.count <= 100 else {
            completion(NSError(domain: "Worknity.Groups", code: 1, userInfo: [NSLocalizedDescriptionKey: AppL10n.text("Συμπλήρωσε σωστά το όνομα συνομιλίας.")])); return
        }
        let db = Firestore.firestore()
        let store = db.collection("stores").document(storeID)
        let group = groupID.map { store.collection("groups").document($0) } ?? store.collection("groups").document()
        db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                let data = try transaction.getDocument(store).data() ?? [:]
                guard StoreAdministration.roles(from: data).can(.groups, uid: uid) else {
                    throw NSError(domain: "Worknity.Groups", code: 2, userInfo: [NSLocalizedDescriptionKey: AppL10n.text("Δεν έχεις δικαίωμα διαχείρισης αυτού του καταστήματος.")])
                }
                let roles = StoreAdministration.roles(from: data)
                guard ConversationAccess.validSelection(participantIDs, storeMembers: roles.participants, editor: uid) else {
                    throw NSError(domain: "Worknity.Groups", code: 4, userInfo: [NSLocalizedDescriptionKey: AppL10n.text("Επίλεξε μέλη του καταστήματος και κράτησε τον εαυτό σου στην ομάδα.")])
                }
                if groupID != nil {
                    let existing = try transaction.getDocument(group)
                    guard existing.exists,
                          ConversationAccess.allows(uid: uid, storeMembers: roles.participants, participantIDs: ConversationAccess.participants(in: existing.data() ?? [:], key: "participantIDs")) else {
                        throw NSError(domain: "Worknity.Groups", code: 3, userInfo: [NSLocalizedDescriptionKey: AppL10n.text("Δεν έχεις πρόσβαση σε αυτή τη συνομιλία.")])
                    }
                    transaction.updateData(["name": name, "participantIDs": participantIDs.sorted()], forDocument: group)
                } else {
                    transaction.setData(["name": name, "participantIDs": participantIDs.sorted(), "createdBy": uid, "createdAt": FieldValue.serverTimestamp()], forDocument: group)
                }
                return nil
            } catch { errorPointer?.pointee = error as NSError; return nil }
        }) { _, error in DispatchQueue.main.async { completion(error) } }
    }
}

struct ConversationSettingsView: View {
    @ObservedObject var access: StoreAccessViewModel
    var conversation: StoreConversation? // nil creates a new group
    @StateObject private var directory = StoreSettingsMembers()
    @State private var selectedMembers: Set<String> = []
    @State private var initialized = false
    @State private var search = ""
    @State private var name = ""
    @State private var saving = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AccountPageBanner(title: conversation == nil ? "Νέα ομάδα" : "Ρυθμίσεις συνομιλίας", subtitle: "Επίλεξε ποιοι συμμετέχουν στη συζήτηση.", symbol: "person.3")
                    Text("Όνομα συνομιλίας").font(.headline)
                    TextField("Όνομα συνομιλίας", text: $name).storeInput()
                    memberSelection
                    if let error { Text(error).font(.footnote).foregroundStyle(.red) }
                    Button(conversation == nil ? "Δημιουργία ομάδας" : "Αποθήκευση") {
                        saving = true
                        let completion: (Error?) -> Void = { failure in
                            saving = false
                            if let failure { error = failure.localizedDescription } else { dismiss() }
                        }
                        if conversation?.id == "general" {
                            StoreAdministration.update(storeID: access.storeID, change: .generalConversation(name, selectedMembers), completion: completion)
                        } else {
                            StoreConversations.save(storeID: access.storeID, groupID: conversation?.groupID, name: name, participantIDs: selectedMembers, completion: completion)
                        }
                    }
                    .buttonStyle(StorePrimaryButtonStyle())
                    .disabled(saving || !access.can(.groups) || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.count > 100 || !ConversationAccess.validSelection(selectedMembers, storeMembers: access.roles.participants, editor: Auth.auth().currentUser?.uid ?? ""))
                }
                .padding(20)
            }
            .background { StoreBackdrop() }
            .navigationTitle(conversation == nil ? "Νέα ομάδα" : "Ρυθμίσεις συνομιλίας")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Κλείσιμο") { dismiss() } } }
            .onAppear {
                guard !initialized else { return }
                initialized = true
                name = conversation?.name ?? ""
                if let conversation {
                    selectedMembers = Set(conversation.participantIDs ?? Array(access.roles.participants))
                        .intersection(access.roles.participants)
                } else if let uid = Auth.auth().currentUser?.uid {
                    selectedMembers = [uid]
                }
            }
            .task(id: access.roles.participants.sorted()) {
                selectedMembers.formIntersection(access.roles.participants)
                directory.load(ids: access.roles.participants.sorted())
            }
            .tint(StoreDesign.ink)
        }
    }

    private var memberSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Πρόσβαση στη συνομιλία").font(.headline)
                Spacer()
                Text(selectedMembers.count, format: .number)
                    .foregroundStyle(.secondary)
            }
            Text("Μόνο τα επιλεγμένα μέλη συμμετέχουν. Τα νέα μέλη αποκτούν πρόσβαση και στο προηγούμενο ιστορικό.")
                .font(.footnote).foregroundStyle(.secondary)
            TextField("Αναζήτηση μελών", text: $search).storeInput()
            HStack {
                Button("Επιλογή όλων") { selectedMembers = access.roles.participants }
                Spacer()
                Button("Μόνο εγώ") {
                    selectedMembers = Set([Auth.auth().currentUser?.uid].compactMap { $0 })
                }
            }
            .font(.subheadline)
            if directory.isLoading { ProgressView() }
            if let error = directory.error {
                Text(error).font(.footnote).foregroundStyle(.red)
                Button("Δοκιμή ξανά") { directory.load(ids: access.roles.participants.sorted()) }
            }
            ForEach(directory.members.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.email.localizedCaseInsensitiveContains(search) }) { member in
                let isSelf = member.id == Auth.auth().currentUser?.uid
                Button {
                    if selectedMembers.contains(member.id) { selectedMembers.remove(member.id) }
                    else { selectedMembers.insert(member.id) }
                } label: {
                    HStack(spacing: 12) {
                        UserProfileImageView(urlString: member.photoURL, size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name).foregroundStyle(.primary)
                            if isSelf { Text("Εσύ · Παραμένεις στην ομάδα").font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Image(systemName: selectedMembers.contains(member.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedMembers.contains(member.id) ? StoreDesign.ink : .secondary)
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isSelf || saving)
                .accessibilityAddTraits(selectedMembers.contains(member.id) ? .isSelected : [])
            }
        }
        .padding(20)
        .storeCard()
    }

}
