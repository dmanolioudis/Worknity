//
//  Shift.swift
//  Worknity
//
//  Created by Dee Manolioudis on 15/7/26.
//


import Foundation
import FirebaseFirestore

struct Shift: Identifiable {
    var id: String
    var employeeID: String
    var employeeName: String
    var employeePhotoURL: String? // Προσθήκη φωτογραφίας
    var startTime: Date
    var endTime: Date
    
    // Εξαγωγή ώρας για το UI
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

struct StoreMember: Identifiable, Hashable {
    var id: String
    var fullName: String
    var photoURL: String?
}
