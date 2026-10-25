import Foundation
import FirebaseAuth
import FirebaseFirestore

/// All mutations re-read current roles in a transaction, including retries.
/// Firestore Security Rules must enforce the same constraints on the server.
enum StoreAdministration {
    enum Change {
        case details(name: String, address: String, phone: String)
        case generalConversation(String, Set<String>)
        case addMember(String)
        case manager(String, Bool, Set<StorePermission>)
        case removeMember(String)
    }

    static func roles(from data: [String: Any]) -> StoreRoles {
        StoreRoles(manager: data["manager"] as? String ?? "",
                   managers: data["managers"] as? [String],
                   participants: data["participants"] as? [String] ?? [],
                   permissions: data["managerPermissions"] as? [String: [String]])
    }

    static func update(storeID: String, change: Change, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(failure("Δεν έχεις δικαίωμα διαχείρισης αυτού του καταστήματος.")); return
        }
        let db = Firestore.firestore()
        let reference = db.collection("stores").document(storeID)
        db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(reference)
                guard let data = snapshot.data() else { throw failure("Το κατάστημα δεν είναι διαθέσιμο.") }
                var roles = roles(from: data)
                guard roles.managers.contains(uid) else { throw StoreRoles.Failure.unauthorized }
                var updates: [String: Any] = [:]
                switch change {
                case let .details(name, address, phone):
                    guard roles.can(.storeDetails, uid: uid) else { throw StoreRoles.Failure.unauthorized }
                    let fields = ["name": name, "address": address, "phone": phone]
                        .mapValues { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    guard fields.values.allSatisfy({ !$0.isEmpty }),
                          fields["name"]!.count <= 100, fields["address"]!.count <= 300,
                          fields["phone"]!.count <= 40 else {
                        throw failure("Συμπλήρωσε σωστά όλα τα στοιχεία του καταστήματος.")
                    }
                    updates = fields
                case let .generalConversation(value, participants):
                    guard roles.can(.groups, uid: uid) else { throw StoreRoles.Failure.unauthorized }
                    let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty, name.count <= 100 else { throw failure("Συμπλήρωσε σωστά το όνομα συνομιλίας.") }
                    guard ConversationAccess.validSelection(participants, storeMembers: roles.participants, editor: uid),
                          ConversationAccess.allows(uid: uid, storeMembers: roles.participants, participantIDs: ConversationAccess.participants(in: data, key: "generalChatParticipantIDs")) else {
                        throw failure("Επίλεξε μέλη του καταστήματος και κράτησε τον εαυτό σου στην ομάδα.")
                    }
                    updates["groupChatName"] = name
                    updates["generalChatParticipantIDs"] = participants.sorted()
                case .addMember(let memberID):
                    guard roles.can(.members, uid: uid) else { throw StoreRoles.Failure.unauthorized }
                    roles.participants.insert(memberID)
                case let .manager(memberID, enabled, grants):
                    try roles.changeManager(memberID, enabled: enabled, grants: grants, actor: uid)
                case .removeMember(let memberID):
                    try roles.remove(memberID, actor: uid)
                }
                // Keep the legacy primary manager while it still has that role.
                let oldPrimary = data["manager"] as? String ?? ""
                updates["manager"] = roles.can(.members, uid: oldPrimary) ? oldPrimary : roles.managers.filter { roles.can(.members, uid: $0) }.sorted().first!
                updates["managers"] = roles.managers.sorted()
                updates["participants"] = roles.participants.sorted()
                updates["managerPermissions"] = roles.permissions
                transaction.updateData(updates, forDocument: reference)
                return nil
            } catch {
                let message: String
                switch error {
                case StoreRoles.Failure.unauthorized: message = "Δεν έχεις δικαίωμα διαχείρισης αυτού του καταστήματος."
                case StoreRoles.Failure.lastManager: message = "Πρέπει να παραμείνει τουλάχιστον ένας manager με δικαίωμα διαχείρισης μελών και ρόλων."
                case StoreRoles.Failure.missingMember: message = "Το άτομο δεν είναι πλέον μέλος του καταστήματος."
                default:
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                errorPointer?.pointee = failure(message)
                return nil
            }
        }) { _, error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    private static func failure(_ message: String) -> NSError {
        NSError(domain: "Worknity.StoreAdministration", code: 1,
                userInfo: [NSLocalizedDescriptionKey: AppL10n.text(message)])
    }
}

final class StoreAccessViewModel: ObservableObject {
    @Published private(set) var data: [String: Any] = [:]
    @Published private(set) var isLoading = true
    @Published private(set) var error: String?
    let storeID: String
    private var listener: ListenerRegistration?

    var roles: StoreRoles { StoreAdministration.roles(from: data) }
    var isManager: Bool { roles.managers.contains(Auth.auth().currentUser?.uid ?? "") }
    func can(_ permission: StorePermission) -> Bool { roles.can(permission, uid: Auth.auth().currentUser?.uid ?? "") }
    var name: String { data["name"] as? String ?? "" }
    var address: String { data["address"] as? String ?? "" }
    var phone: String { data["phone"] as? String ?? "" }
    var chatName: String {
        let name = data["groupChatName"] as? String ?? ""
        return name.isEmpty ? AppL10n.text("Γενική Ομαδική Συνομιλία") : name
    }

    init(storeID: String) {
        self.storeID = storeID
        listener = Firestore.firestore().collection("stores").document(storeID)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isLoading = false
                    self.error = error?.localizedDescription
                    self.data = error == nil ? snapshot?.data() ?? [:] : [:]
                }
            }
    }

    deinit { listener?.remove() }
}

final class StoreSettingsMembers: ObservableObject {
    struct Member: Identifiable {
        let id: String
        let name: String
        let email: String
        let photoURL: String?
    }
    @Published private(set) var members: [Member] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    private var generation = UUID()

    func load(ids: [String]) {
        let generation = UUID()
        self.generation = generation
        isLoading = true
        error = nil
        let group = DispatchGroup()
        var loaded: [Member] = []
        var loadError: String?
        for uid in ids {
            group.enter()
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
                DispatchQueue.main.async {
                    defer { group.leave() }
                    if let error { loadError = error.localizedDescription }
                    let data = snapshot?.data() ?? [:]
                    loaded.append(Member(id: uid, name: data["fullName"] as? String ?? AppL10n.text("Μέλος"),
                                         email: data["email"] as? String ?? "", photoURL: data["photoURL"] as? String))
                }
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self, self.generation == generation else { return }
            self.members = loaded.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            self.error = loadError
            self.isLoading = false
        }
    }
}
