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
    @Published private(set) var initialFirstUnseenPostID: String?
    
    let storeID: String
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var roleListener: ListenerRegistration?
    private var didCaptureInitialReadTarget = false
    
    // Αποθηκεύει το τελευταίο post που είδε ο χρήστης
    var lastSeenPostID: String {
        get { UserDefaults.standard.string(forKey: "lastSeen_\(storeID)") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lastSeen_\(storeID)") }
    }

    private var lastSeenPostTimestamp: TimeInterval {
        get { UserDefaults.standard.double(forKey: "lastSeenPostTimestamp_\(storeID)") }
        set { UserDefaults.standard.set(newValue, forKey: "lastSeenPostTimestamp_\(storeID)") }
    }
    
    init(storeID: String) {
        self.storeID = storeID
        checkIfManager()
        startListeningForPosts()
    }
    
    deinit {
        roleListener?.remove()
        listener?.remove() // Καθαρίζουμε τον listener όταν κλείνει το view
    }
    
    func checkIfManager() {
        roleListener?.remove()
        roleListener = db.collection("stores").document(storeID).addSnapshotListener { [weak self] snapshot, error in
            let roles = StoreAdministration.roles(from: error == nil ? snapshot?.data() ?? [:] : [:])
            DispatchQueue.main.async {
                self?.isManager = roles.can(.posts, uid: Auth.auth().currentUser?.uid ?? "")
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

                // Migrate the older ID-only tracking the first time this code sees it.
                if self.lastSeenPostTimestamp == 0,
                   let storedPost = newRegular.first(where: { $0.id == self.lastSeenPostID }) {
                    self.lastSeenPostTimestamp = storedPost.timestamp.timeIntervalSince1970
                }

                let firstUnseenPostID: String?
                if let lastSeenIndex = newRegular.firstIndex(where: { $0.id == self.lastSeenPostID }),
                   lastSeenIndex + 1 < newRegular.count {
                    firstUnseenPostID = newRegular[lastSeenIndex + 1].id
                } else {
                    firstUnseenPostID = nil
                }
                
                DispatchQueue.main.async {
                    if !self.didCaptureInitialReadTarget {
                        self.initialFirstUnseenPostID = firstUnseenPostID
                        self.didCaptureInitialReadTarget = true
                    }
                    self.pinnedPosts = newPinned.sorted { $0.timestamp > $1.timestamp }
                    self.regularPosts = newRegular
                }
            }
    }
    
    func togglePin(postID: String, currentPinned: Bool) {
        guard isManager else { return }
        // Αλλάζει την κατάσταση του isPinned στο Firestore στο αντίθετο
        db.collection("stores").document(storeID)
            .collection("posts").document(postID)
            .updateData(["isPinned": !currentPinned]) { error in
                if let error = error {
                    print("Error updating pin status: \(error.localizedDescription)")
                }
            }
    }

    func markPostAsSeen(_ post: StorePost) {
        let timestamp = post.timestamp.timeIntervalSince1970
        guard timestamp >= lastSeenPostTimestamp else { return }

        lastSeenPostTimestamp = timestamp
        lastSeenPostID = post.id
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
