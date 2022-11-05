//
//  Service.swift
//  Uber
//
//  Created by Beavean on 17.10.2022.
//

import Firebase
import GeoFire

//MARK: - Driver Service

struct DriverService {
    
    static let shared = DriverService()
    
    func observeTrips(completion: @escaping(Trip) -> Void) {
        K.FB.tripsReference.observe(.childAdded) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func observeTripCancelled(trip: Trip, completion: @escaping() -> Void) {
        K.FB.tripsReference.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { _ in
            completion()
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = ["driverUid": uid, "state": TripState.accepted.rawValue] as [String: Any]
        K.FB.tripsReference.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func updateTripState(trip: Trip, state: TripState, completion: @escaping(Error?, DatabaseReference) -> Void) {
        K.FB.tripsReference.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
        if state == .completed {
            K.FB.tripsReference.child(trip.passengerUid).removeAllObservers()
        }
    }
    
    func updateDriverLocation(location: CLLocation) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let geoFire = GeoFire(firebaseRef: K.FB.driverLocationsReference)
        geoFire.setLocation(location, forKey: uid)
    }
}

//MARK: - Passenger Service

struct PassengerService {
    
    static let shared = PassengerService()

    func fetchDrivers(location: CLLocation, completion: @escaping (User) -> Void) {
        let geoFire = GeoFire(firebaseRef: K.FB.driverLocationsReference)
        K.FB.driverLocationsReference.observe(.value) { snapshot in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered, with: { uid, location in
                Service.shared.fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }
    }
    
    func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D, _ destinationCoordinates: CLLocationCoordinate2D, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        let values = ["pickupCoordinates": pickupArray,
                      "destinationCoordinates": destinationArray,
                      "state": TripState.requested.rawValue] as [String : Any]
        K.FB.tripsReference.child(uid).updateChildValues(values, withCompletionBlock: completion)
    }
    
    func observeCurrentTrip(completion: @escaping(Trip) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        K.FB.tripsReference.child(uid).observe(.value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    
    func deleteTrip(completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        K.FB.tripsReference.child(uid).removeValue(completionBlock: completion)
    }
    
    func saveLocation(locationString: String, type: LocationType, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let key: String = type == .home ? "homeLocation" : "workLocation"
        K.FB.usersReference.child(uid).child(key).setValue(locationString, withCompletionBlock: completion)
    }
}

//MARK: - Shared Service

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(uid: String, completion: @escaping (User) -> Void) {
        K.FB.usersReference.child(uid).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
        }
    }
}
