//
//  RegisterViewController.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
final class RegisterViewController: UIViewController,UITextFieldDelegate {
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var firstnameField: UITextField!
    
    @IBOutlet weak var lastnameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var labelFirstName: UILabel!
    
    @IBOutlet weak var labelLastName: UILabel!
    
    @IBOutlet weak var labelEmail: UILabel!
    
    @IBOutlet weak var labelPassword: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelFirstName.layer.borderWidth = 1
        labelLastName.layer.borderWidth = 1
        labelEmail.layer.borderWidth = 1
        labelPassword.layer.borderWidth = 1
        labelFirstName.layer.cornerRadius = 20
        labelLastName.layer.cornerRadius = 20
        labelEmail.layer.cornerRadius = 20
        labelPassword.layer.cornerRadius = 20
        firstnameField.delegate = self
        lastnameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    @IBAction func registerTapped(_ sender: Any) {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstnameField.resignFirstResponder()
        lastnameField.resignFirstResponder()
        guard let firstName = firstnameField.text,
              let lastName = lastnameField.text,
              let email = emailField.text,
              let password = passwordField.text,!email.isEmpty,!password.isEmpty,!firstName.isEmpty,!lastName.isEmpty
        else{
            let alert = UIAlertController(title: "Ooops", message: "You haven't typed enough infor yet", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true)
            return
        }
        guard let password = passwordField.text, !password.isEmpty, password.count >= 6
        else {
            let alert = UIAlertController(title: "Password Problem", message: "Your password must be 6 or greater than 6 characters", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            present(alert,animated: true)
            return
        }
        spinner.show(in: view)
        //Firebase Login
        DatabaseManager.shared.userExists(with: email, completion: {[weak self]exists in
            guard let strongSelf = self else{
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            guard !exists else {
                //user already exists
                strongSelf.alertUserLoginError(message: "Looks like a user account for that email address already exists")
                return
            }
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password,completion: {authResult, error in
                
                
                guard authResult != nil, error == nil else{
                    print("Error creating user")
                    return
                }
//                                let user = Auth.auth().currentUser
//                                    user?.sendEmailVerification(completion: { error in
//                                        if let error = error {
//                                            print("Error sending verification email: \(error.localizedDescription)")
//                                            return
//                                        }
//                                        DispatchQueue.main.async {
//                                            strongSelf.alertVerify(message: "A verification email has been sent to your email address. Please verify your account before logging in.")
//                                        }
//                                    })
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                    if success{
                        //upload image
                       
                        
                    }
                })
            })
        })
        
    }
    func alertUserLoginError(message: String = "Please enter all information to create a new account"){
        let alert = UIAlertController(title: "Woops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss", style: .cancel, handler: { acting in
            self.navigationController?.popToRootViewController(animated: true)
        }))
        present(alert, animated: true)
        
    }
    func alertVerify(message: String){
        let alert = UIAlertController(title: "Registered successfully !", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss", style: .cancel, handler: { acting in
            self.navigationController?.popToRootViewController(animated: true)
        }))
        present(alert, animated: true)
    }
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField{
        case firstnameField:
                lastnameField.becomeFirstResponder()
            case lastnameField:
                emailField.becomeFirstResponder()
            case emailField:
                passwordField.becomeFirstResponder()
            case passwordField:
                textField.resignFirstResponder()
            default:
                break
            }
            return true
    }
}




