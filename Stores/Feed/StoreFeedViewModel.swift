//
//  StoreFeedViewModel.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//


//
//  StoreFeedViewModel.swift
//  Worknity
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class StoreFeedViewModel: ObservableObject {
    @Published var pinnedPosts: [StorePost] = []
    @Published var regularPosts: [StorePost] = []
    @Published var isManager: Bool = false
    
    let storeID: String
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // Αποθηκεύει το τελευταίο post που είδε ο χρήστης
    var lastSeenPostID: String {
        get { UserDefaults.standard.string(forKey: "lastSeen_\(storeID)") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastSeen_\(storeID)") }
    }
    
    init(storeID: String) {
        self.storeID = storeID
        checkIfManager()
        startListeningForPosts()
    }
    
    deinit {
        listener?.remove() // Καθαρίζουμε τον listener όταν κλείνει το view
    }
    
    func checkIfManager() {
        guard let currentUser = Auth.auth().currentUser else { return }
        db.collection("stores").document(storeID).getDocument { snapshot, error in
            if let data = snapshot?.data(), let managerID = data["manager"] as? String {
                DispatchQueue.main.async {
                    self.isManager = (managerID == currentUser.uid)
                }
            }
        }
    }
    
    func startListeningForPosts() {
        // Ακούμε ζωντανά την collection posts του καταστήματος
        listener = db.collection("stores").document(storeID).collection("posts")
            .order(by: "timestamp", descending: false) // Παλιά πάνω, Νέα κάτω
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                var newPinned: [StorePost] = []
                var newRegular: [StorePost] = []
                
                for doc in documents {
                    let post = StorePost(id: doc.documentID, data: doc.data())
                    if post.isPinned {
                        newPinned.append(post)
                    } else {
                        newRegular.append(post)
                    }
                }
                
                DispatchQueue.main.async {
                    // Επειδή τα pinned τα θέλουμε στην κορυφή, τα βάζουμε με σειρά (τα πιο πρόσφατα καρφιτσωμένα πρώτα)
                    self.pinnedPosts = newPinned.sorted { $0.timestamp > $1.timestamp }
                    self.regularPosts = newRegular
                }
            }
    }
    
    func togglePin(postID: String, currentPinned: Bool) {
        // Αλλάζει την κατάσταση του isPinned στο Firestore στο αντίθετο
        db.collection("stores").document(storeID)
            .collection("posts").document(postID)
            .updateData(["isPinned": !currentPinned]) { error in
                if let error = error {
                    print("Error updating pin status: \(error.localizedDescription)")
                }
            }
    }
    
    func toggleLike(postID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let postRef = db.collection("stores").document(storeID).collection("posts").document(postID)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            var likes = postDocument.data()?["likes"] as? [String] ?? []
            
            if likes.contains(uid) {
                likes.removeAll { $0 == uid } // Αν έχει κάνει already, βγάλτο (Unlike)
            } else {
                likes.append(uid) // Αλλιώς βάλτο (Like)
            }
            
            transaction.updateData(["likes": likes], forDocument: postRef)
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
            }
        }
    }
}
