import Foundation
import FirebaseFirestore

class AddMembersViewModel: ObservableObject {
    private var db = Firestore.firestore()
    @Published var statusMessage: String = ""
    
    func addMember(email: String, storeID: String, completion: @escaping (Bool) -> Void) {
        // 1. Βρες το UID του χρήστη από το email
        db.collection("users").whereField("email", isEqualTo: email.lowercased()).getDocuments { snapshot, error in
            if let error = error {
                DispatchQueue.main.async { self.statusMessage = "Σφάλμα: \(error.localizedDescription)" }
                completion(false); return
            }
            
            guard let userDoc = snapshot?.documents.first else {
                DispatchQueue.main.async { self.statusMessage = "Δεν βρέθηκε χρήστης με αυτό το email." }
                completion(false); return
            }
            
            let userID = userDoc.documentID
            
            // 2. Πρόσθεσε το UID στο πεδίο "participants" του καταστήματος
            self.db.collection("stores").document(storeID).updateData([
                "participants": FieldValue.arrayUnion([userID])
            ]) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.statusMessage = "Σφάλμα: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self.statusMessage = "Ο χρήστης προστέθηκε επιτυχώς!"
                        completion(true)
                    }
                }
            }
        }
    }
}
