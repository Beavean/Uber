//
//  Constants.swift
//  Uber
//
//  Created by Beavean on 05.11.2022.
//

import Foundation
import Firebase

struct K {
    
    //MARK: - UI strings
    
    struct UI {
        static let locationCellReuseIdentifier = String(describing: LocationCell.self)
    }
    
    //MARK: - Firebase references
    
    struct FB {
        private static let databaseReference = Database.database().reference()
        static let usersReference = databaseReference.child("users")
        static let driverLocationsReference = databaseReference.child("driver-locations")
        static let tripsReference = databaseReference.child("trips")
    }
}
