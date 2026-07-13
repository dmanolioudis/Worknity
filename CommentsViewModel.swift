//
//  CommentsViewModel.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//


//
//  CommentsViewModel.swift
//  Worknity
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    @Published var comments: [PostComment] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    let storeID: String
    let postID: String
    
    init(storeID: String, postID: String) {
        self.storeID = storeID
        self.postID = postID
        observeComments()
    }
    
    deinit {
        // Σημαντικό: Σταματάει να ακούει τη βάση όταν κλείνει το παράθυρο για εξοικονόμηση δεδομένων
        listener?.remove()
    }
    
    // Live παρακολούθηση των σχολίων
    func observeComments() {
        isLoading = true
        listener = db.collection("stores").document(storeID)
            .collection("posts").document(postID)
            .collection("comments")
            .order(by: "timestamp", descending: false) // Τα παλαιότερα πάνω, τα νεότερα κάτω
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                guard let documents = snapshot?.documents else {
                    print("Error fetching comments: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                self.comments = documents.map { PostComment(id: $0.documentID, data: $0.data()) }
            }
    }
    
    // Προσθήκη νέου σχολίου
    func addComment(content: String, completion: @escaping () -> Void) {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let user = Auth.auth().currentUser, !trimmedContent.isEmpty else { return }
        
        // Παίρνουμε τα στοιχεία του προφίλ του χρήστη που σχολιάζει
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            
            let userData = snapshot?.data()
            let authorName = userData?["fullName"] as? String ?? "Μέλος"
            let authorProfilePic = userData?["photoURL"] as? String
            
            let commentData: [String: Any] = [
                "postID": self.postID,
                "content": trimmedContent,
                "authorID": user.uid,
                "authorName": authorName,
                "authorProfilePic": authorProfilePic as Any,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            self.db.collection("stores").document(self.storeID)
                .collection("posts").document(self.postID)
                .collection("comments").document().setData(commentData) { error in
                    if error == nil {
                        completion() // Καθαρίζει το textfield στην οθόνη
                    }
                }
        }
    }
}