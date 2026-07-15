//
//  Store.swift
//  Worknity
//
//  Created by Dee Manolioudis on 27/2/26.
//


struct Store: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let manager: String
    let participants: [String] 
    
}
