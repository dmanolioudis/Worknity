//
//  ChatMessage.swift
//  Worknity
//
//  Created by Dee Manolioudis on 8/7/26.
//


// ChatMessage.swift
import Foundation
import FirebaseFirestore
import UIKit

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderID: String
    let senderName: String
    let text: String
    let timestamp: Date
    var mediaURL: String?
    var mediaType: String?
    var thumbnailURL: String? // ΝΕΟ: URL για έτοιμη εικόνα προεπισκόπησης βίντεο στο cloud
    var reactions: [String: String]?
    var readBy: [String]?
    
    // Τοπικά πεδία για Optimistic UI (Αγνοούνται αυτόματα από το Firebase κατά το encoding/decoding)
    var isSending: Bool? = false
    var localImage: UIImage? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, senderID, senderName, text, timestamp, mediaURL, mediaType, thumbnailURL, reactions, readBy
    }
}
