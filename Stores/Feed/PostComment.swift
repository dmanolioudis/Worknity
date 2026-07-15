//
//  PostComment.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//


//
//  PostComment.swift
//  Worknity
//

import Foundation
import FirebaseFirestore

struct PostComment: Identifiable, Hashable {
    var id: String
    var postID: String
    var content: String
    var authorID: String
    var authorName: String
    var authorProfilePic: String?
    var timestamp: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.postID = data["postID"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.authorID = data["authorID"] as? String ?? ""
        self.authorName = data["authorName"] as? String ?? "Άγνωστος"
        self.authorProfilePic = data["authorProfilePic"] as? String
        
        if let ts = data["timestamp"] as? Timestamp {
            self.timestamp = ts.dateValue()
        } else {
            self.timestamp = Date()
        }
    }
}