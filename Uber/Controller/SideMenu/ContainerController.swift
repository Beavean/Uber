//
//  ContainerController.swift
//  Uber
//
//  Created by Beavean on 31.10.2022.
//

import UIKit
import Firebase

class ContainerController: UIViewController {
    
    //MARK: - Properties
    
    private let homeController = HomeController()
    private var menuController: MenuController!
    private var isExpanded = false
    var user: User? {
        didSet {
            guard let user else { return }
            homeController.user = user
            configureMenuController(withUser: user)
        }
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundColor
        configureHomeController()
        fetchUserData()
    }
    
    //MARK: - API
    
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return  }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
        }
    }
    
    //MARK: - Helpers
    
    private func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
    }
    
    private func configureMenuController(withUser user: User) {
        menuController = MenuController(user: user)
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
        menuController.view.frame = CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.height - 40)
    }
    
    private func animateMenu(shouldExpand: Bool) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.homeController.view.frame.origin.x = self.view.frame.width - 80
            }
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
                self.homeController.view.frame.origin.x = 0
            }
        }
    }
}

extension ContainerController: HomeControllerDelegate {
    
    func handleMenuToggle() {
        isExpanded.toggle()
        animateMenu(shouldExpand: isExpanded)
    }
}
