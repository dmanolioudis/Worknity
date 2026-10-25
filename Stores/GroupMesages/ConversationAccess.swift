import Foundation

/// Missing participant lists preserve legacy store-wide conversations.
enum ConversationAccess {
    static func participants(in data: [String: Any], key: String) -> [String]? {
        guard let value = data[key] else { return nil }
        // An invalid explicit ACL must never become a store-wide legacy group.
        return value as? [String] ?? []
    }

    static func allows(uid: String, storeMembers: Set<String>, participantIDs: [String]?) -> Bool {
        !uid.isEmpty && storeMembers.contains(uid) && (participantIDs.map { $0.contains(uid) } ?? true)
    }

    static func validSelection(_ selected: Set<String>, storeMembers: Set<String>, editor: String) -> Bool {
        !selected.isEmpty && selected.contains(editor) && selected.isSubset(of: storeMembers)
    }
}
