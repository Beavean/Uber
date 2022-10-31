//
//  ContainerController.swift
//  Uber
//
//  Created by Beavean on 31.10.2022.
//

import UIKit

class ContainerController: UIViewController {
    
    //MARK: - Properties
    
    private let homeController = HomeController()
    private var menuController = MenuController()
    private var isExpanded = false
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHomeController()
        configureMenuController()
    }
    
    //MARK: - Selectors
    
    
    
    //MARK: - Helpers
    
    private func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
    }
    
    private func configureMenuController() {
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
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
