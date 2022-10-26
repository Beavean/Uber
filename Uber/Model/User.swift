//
//  User.swift
//  Uber
//
//  Created by Beavean on 17.10.2022.
//

import Foundation
import CoreLocation

enum AccountType: Int {
    case passenger
    case driver
}

struct User {
    
    let fullName: String
    let email: String
    var accountType: AccountType!
    var location: CLLocation?
    let uid: String
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.fullName = dictionary["fullName"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        if let index = dictionary["accountType"] as? Int {
            self.accountType = AccountType(rawValue: index)
        }
    }
}
