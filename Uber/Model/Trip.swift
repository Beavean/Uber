//
//  Trip.swift
//  Uber
//
//  Created by Beavean on 26.10.2022.
//

import CoreLocation

enum TripState: Int {
    case requested
    case accepted
    case driverArrived
    case inProgress
    case completed
}

struct Trip {
    
    var pickupCoordinates: CLLocationCoordinate2D!
    var destinationCoordinates: CLLocationCoordinate2D!
    let passengerUid: String
    var driverUid: String?
    var state: TripState!
    
    init(passengerUid: String, dictionary: [String: Any]) {
        self.passengerUid = passengerUid
        if let pickupCoordinates = dictionary["pickupCoordinates"] as? NSArray {
            guard let latitude = pickupCoordinates[0] as? CLLocationDegrees,
            let longitude = pickupCoordinates[1] as? CLLocationDegrees else { return }
            self.pickupCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        if let destinationCoordinates = dictionary["destinationCoordinates"] as? NSArray {
            guard let latitude = destinationCoordinates[0] as? CLLocationDegrees,
            let longitude = destinationCoordinates[1] as? CLLocationDegrees else { return }
            self.destinationCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        self.driverUid = dictionary["driverUid"] as? String ?? ""
        if let state = dictionary["state"] as? Int {
            self.state = TripState(rawValue: state)
        }
        
    }
}


