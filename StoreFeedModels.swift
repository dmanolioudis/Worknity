//
//  PostMediaType.swift
//  Worknity
//
//  Created by Dee Manolioudis on 12/7/26.
//


//
//  StoreFeedModels.swift
//  Worknity
//

import Foundation
import FirebaseFirestore

enum PostMediaType: String, Codable {
    case image
    case video
    case file
    case none
}

struct StorePost: Identifiable, Hashable {
    var id: String
    var storeID: String
    var content: String
    var mediaURL: String?
    var mediaType: PostMediaType
    var fileName: String? // Όνομα αρχείου για έγγραφα
    var isPinned: Bool
    var timestamp: Date
    var authorID: String
    var authorName: String
    var authorProfilePic: String?
    var likes: [String]
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.storeID = data["storeID"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.mediaURL = data["mediaURL"] as? String
        self.fileName = data["fileName"] as? String
        
        if let typeStr = data["mediaType"] as? String, let type = PostMediaType(rawValue: typeStr) {
            self.mediaType = type
        } else {
            self.mediaType = .none
        }
        
        self.isPinned = data["isPinned"] as? Bool ?? false
        
        if let ts = data["timestamp"] as? Timestamp {
            self.timestamp = ts.dateValue()
        } else {
            self.timestamp = Date()
        }
        
        self.authorID = data["authorID"] as? String ?? ""
        self.authorName = data["authorName"] as? String ?? "Άγνωστος"
        self.authorProfilePic = data["authorProfilePic"] as? String
        self.likes = data["likes"] as? [String] ?? []
    }
}
