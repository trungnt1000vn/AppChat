//
//  ProfileViewController.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

import Foundation
import UIKit
import FirebaseAuth
import SDWebImage


class ProfileViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    @IBOutlet weak var avaPhoto: UIImageView!
    
    @IBOutlet weak var coverPhoto: UIImageView!
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var copyButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avaPhoto.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action:#selector(avaTapped))
        avaPhoto.addGestureRecognizer(gesture)
        avaPhoto.layer.cornerRadius = 50
        avaPhoto.contentMode = .scaleAspectFill
        coverPhoto.contentMode = .scaleAspectFill
        coverPhoto.alpha = 0.5
        logoutButton.layer.cornerRadius = 20
        emailField.layer.borderWidth = 1
        emailField.layer.cornerRadius = 25
        nameField.layer.borderWidth = 1
        nameField.layer.cornerRadius = 25
        nameLabel.frame = CGRect(x: nameField.left + 16, y: nameField.top  , width: nameField.width - 32, height: nameField.height)
        emailLabel.frame = CGRect(x: emailField.left + 16, y: emailField.top  , width: emailField.width - 32, height: emailField.height)
        
        
        if (checkDarkMode() == true){
            if let image = UIImage(named: "Copy.png"){
                copyButton.setImage(image, for: .normal)
                emailField.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
                nameField.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
            }
        }
        if (checkDarkMode() == false){
            if let image = UIImage(named: "copyblack.png"){
                copyButton.setImage(image, for: .normal)
                emailField.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
                nameField.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
            }
        }
        guard let email = UserDefaults.standard.value(forKey: "email")as? String else {
            return
        }
        guard let name = UserDefaults.standard.value(forKey: "name")as? String
        else {
            return
        }
        nameLabel.text = "Name : \(name)"
        emailLabel.text = "Email : \(email)"
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = safeEmail + "_profile_picture.png"
        let path = "images/"+filename
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result{
            case .success(let url):
                self.avaPhoto.sd_setImage(with: url, completed: nil)
                self.coverPhoto.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download url : \(error)")
            }
        })
    }
    
    @objc func avaTapped() {
        presentPhotoActionSheet()
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if (checkDarkMode() == true){
                if let image = UIImage(named: "Copy.png"){
                    copyButton.setImage(image, for: .normal)
                    emailField.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
                    nameField.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
                }
            }
            if (checkDarkMode() == false){
                if let image = UIImage(named: "copyblack.png"){
                    copyButton.setImage(image, for: .normal)
                    emailField.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
                    nameField.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
                }
            }
        }
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        UserDefaults.standard.set(nil, forKey: "email")
        UserDefaults.standard.set(nil, forKey: "name")
        let actionSheet = UIAlertController(title: "Are you sure want to log out ?", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive,handler: {[weak self] _ in
            guard let strongSelf = self else{
                return
            }
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "Login")
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav,animated: true)
            }
            catch {
                print("Failed to log out")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: nil))
        self.present(actionSheet,animated: true)
    }
    
    @IBAction func copyTapped(_ sender: Any) {
        copyAction()
        if(checkDarkMode() == true){
            if let image = UIImage(named: "checked"){
                copyButton.setImage(image, for: .normal)
            }
        }
        if(checkDarkMode() == false){
            if let image = UIImage(named: "checkedblack"){
                copyButton.setImage(image, for: .normal)
            }
        }
    }
    
}

extension ProfileViewController{
    
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Photo", message: "How would you like to select your picture ?", preferredStyle: .actionSheet)
        
        actionSheet.addAction((UIAlertAction(title: "Cancel", style: .cancel,handler: nil)))
        actionSheet.addAction((UIAlertAction(title: "Take Photo", style: .default,handler: {[weak self] _ in
            self?.presentCamera()
            
        })))
        actionSheet.addAction((UIAlertAction(title: "Choose Photo", style: .default,handler: { [weak self] _ in
            self?.presentPhotoPicker()
        })))
        present(actionSheet, animated: true)
    }
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        vc.modalPresentationStyle = .fullScreen
        present(vc,animated: true)
    }
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{
            return
        }
        self.avaPhoto.image = selectedImage
        self.coverPhoto.image = selectedImage
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = "\(safeEmail)_profile_picture.png"
        guard let image = self.avaPhoto.image, let data = image.pngData() else {
            return
        }
        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
            switch result {
            case .success(let downloadUrl):
                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                print(downloadUrl)
            case .failure(let error):
                print("Storage manager error \(error)")
            }
        })
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
extension ProfileViewController{
    func copyAction() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = email
        print("Copied")
        print(email)
    }
}
extension ProfileViewController{
    func checkDarkMode() -> Bool{
        if view.traitCollection.userInterfaceStyle == .dark{
            return true
        }
        return false
    }
}
