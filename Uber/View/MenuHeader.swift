//
//  MenuHeader.swift
//  Uber
//
//  Created by Beavean on 31.10.2022.
//

import UIKit

class MenuHeader: UIView {
    
    //MARK: - Properties
    
//    var user: User? {
//        didSet {
//            fullNameLabel.text = user?.fullName
//            emailLabel.text = user?.email
//        }
//    }
    
    private let user: User
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.addSubview(initialLabel)
        initialLabel.centerX(inView: view)
        initialLabel.centerY(inView: view)
        return view
    }()
    
    private lazy var initialLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 42)
        label.textColor = .white
        label.text = user.firstInitial
        return label
    }()
    
    private lazy var fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.text = user.fullName
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = user.email
        return label
    }()
    
    //MARK: - Lifecycle
    
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)
        backgroundColor = .backgroundColor
        let stack = UIStackView(arrangedSubviews: [fullNameLabel, emailLabel])
        addSubview(profileImageView)
        addSubview(stack)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 4, paddingLeft: 12, width: 64, height: 64)
        profileImageView.layer.cornerRadius = 64 / 2
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    

}
