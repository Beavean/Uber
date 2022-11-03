//
//  AppDelegate.swift
//  Uber
//
//  Created by Beavean on 11.10.2022.
//

import UIKit
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.rootViewController = ContainerController()
        return true
    }
}

