//
//  User.swift
//  Uber
//
//  Created by Beavean on 17.10.2022.
//

import Foundation

struct User {
    
    let fullName: String
    let email: String
    let accountType: Int
    
    init(dictionary: [String: Any]) {
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.accountType = dictionary["accountType"] as? Int ?? 0
    }
}
