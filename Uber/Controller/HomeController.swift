//
//  HomeController.swift
//  Uber
//
//  Created by Beavean on 13.10.2022.
//

import UIKit
import Firebase
import MapKit

final class HomeController: UIViewController {
    
    //MARK: - Properties
    
    private let mapView = MKMapView()

    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        view.backgroundColor = .red
        //        signOut()
    }
    
    //MARK: - API
    
    private func checkIfUserIsLoggedIn() {
        if let _ = Auth.auth().currentUser?.uid {
            configureUI()
        } else {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.showError(error)
        }
    }
    
    //MARK: - Selectors
    
    
    
    //MARK: - Helpers
    
    func configureUI() {
        view.addSubview(mapView)
        mapView.frame = view.frame
    }
}
