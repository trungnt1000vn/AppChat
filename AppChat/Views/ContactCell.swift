//
//  ContactCell.swift
//  AppChat
//
//  Created by Trung on 12/06/2023.
//

import Foundation
import UIKit


class ContactCell : UITableViewCell{
    static let identifier = "ContactCell"
    private let userImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = 25
        image.layer.masksToBounds = true
        return image
    }()
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImage)
        contentView.addSubview(userNameLabel)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        userImage.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        userNameLabel.frame = CGRect(x: userImage.right + 10, y: 25, width: contentView.width - 20 - userImage.width, height: (contentView.height-20)/2)
    }
    
    public func configure(with model:Conversation){
        userNameLabel.text = model.name
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImage.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image URL: \(error)")
            }
        }
    }
}
