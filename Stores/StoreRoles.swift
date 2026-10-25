import Foundation

enum StorePermission: String, CaseIterable, Identifiable {
    case posts, groups, schedule, storeDetails, members
    var id: String { rawValue }
    var title: String {
        switch self {
        case .posts: "Δημοσιεύσεις"
        case .groups: "Δημιουργία και διαχείριση ομάδων"
        case .schedule: "Διαχείριση προγράμματος"
        case .storeDetails: "Στοιχεία καταστήματος"
        case .members: "Διαχείριση μελών και ρόλων"
        }
    }
}

/// Explicit manager lists are authoritative; legacy stores retain their existing permissions.
struct StoreRoles {
    var managers: Set<String>
    var participants: Set<String>
    var permissions: [String: [String]]

    init(manager: String, managers: [String]?, participants: [String], permissions: [String: [String]]? = nil) {
        self.managers = Set(managers ?? (manager.isEmpty ? [] : [manager]))
        self.participants = Set(participants).union(self.managers)
        self.permissions = Dictionary(uniqueKeysWithValues: self.managers.map {
            ($0, permissions == nil ? StorePermission.allCases.map(\.rawValue) : permissions?[$0] ?? [])
        })
    }

    enum Failure: Error { case unauthorized, lastManager, missingMember }

    func can(_ permission: StorePermission, uid: String) -> Bool {
        managers.contains(uid) && (permissions[uid] ?? []).contains(permission.rawValue)
    }

    mutating func changeManager(_ uid: String, enabled: Bool, grants: Set<StorePermission>, actor: String) throws {
        guard can(.members, uid: actor) else { throw Failure.unauthorized }
        guard participants.contains(uid) else { throw Failure.missingMember }
        var updated = self
        if enabled {
            updated.managers.insert(uid)
            updated.permissions[uid] = grants.map(\.rawValue).sorted()
        } else {
            updated.managers.remove(uid)
            updated.permissions.removeValue(forKey: uid)
        }
        try updated.validateAdministrators()
        self = updated
    }

    mutating func remove(_ uid: String, actor: String) throws {
        guard can(.members, uid: actor) else { throw Failure.unauthorized }
        var updated = self
        updated.managers.remove(uid)
        updated.permissions.removeValue(forKey: uid)
        updated.participants.remove(uid)
        try updated.validateAdministrators()
        self = updated
    }

    private func validateAdministrators() throws {
        guard managers.contains(where: { can(.members, uid: $0) }) else { throw Failure.lastManager }
    }
}
