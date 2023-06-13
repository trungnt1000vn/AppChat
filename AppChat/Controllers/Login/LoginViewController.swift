//
//  LoginViewController.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

import Foundation
import UIKit
import FirebaseAuth
import JGProgressHUD
final class LoginViewController: UIViewController, UITextFieldDelegate {
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var forgetButton: UIButton!
    @IBAction func registerButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Register", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Register")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func forgotTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Forgot", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Forgot")
        present(vc, animated: true)
    }
    @IBAction func loginButtonTapped(_ sender: Any) {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text,
              let password = passwordField.text,!email.isEmpty,!password.isEmpty, password.count >= 6
        else{
            alerUserLoginError()
            return
        }
        spinner.show(in: view)
        //Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password,completion: {[weak self] authResult, error in
            
            guard let strongSelf = self else{
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss(animated: true)
            }
            guard let result = authResult, error == nil else{
                print("Failed to log in user with email: \(email)")
                let alert = UIAlertController(title: "Failed to log you in", message: "You've entered a wrong email or password !!!", preferredStyle: .alert)
                let alertActionOK = UIAlertAction(title: "Try Again", style: .default, handler: nil)
                let alertActionCancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { acting in
                    
                    self?.emailField.text = ""
                    self?.passwordField.text = ""
                })
                alert.addAction(alertActionOK)
                alert.addAction(alertActionCancel)
                self?.present(alert,animated: true,completion: nil)
                return
            }
            let user = result.user
            if user.isEmailVerified{
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                DatabaseManager.shared.getDataFor(path: safeEmail, completion: {[weak self] result in
                    switch result {
                    case .success(let data):
                        guard let userData = data as? [String: Any],
                              let firstName = userData["first name"] as? String,
                              let lastName = userData["last_name"] as? String
                        else{
                            print("Failed to get the name")
                            return
                        }
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    case .failure(let error):
                        print ("Failed to read data with error \(error)")
                    }
                })
                
                
                UserDefaults.standard.set(email, forKey: "email")
                
                print("Logged in user : \(user)")
                strongSelf.navigationController?.dismiss(animated: true,completion: nil)
            }
            else {
                //strongSelf.alertUserVerified()
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                DatabaseManager.shared.getDataFor(path: safeEmail, completion: {[weak self] result in
                    switch result {
                    case .success(let data):
                        guard let userData = data as? [String: Any],
                              let firstName = userData["first name"] as? String,
                              let lastName = userData["last_name"] as? String
                        else{
                            print("Failed to get the name")
                            return
                        }
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    case .failure(let error):
                        print ("Failed to read data with error \(error)")
                    }
                })
                
                
                UserDefaults.standard.set(email, forKey: "email")
                
                print("Logged in user : \(user)")
                strongSelf.navigationController?.dismiss(animated: true,completion: nil)
            }
        })
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        label1.layer.borderWidth = 1
        label1.layer.cornerRadius = 20
        label2.layer.borderWidth = 1
        label2.layer.cornerRadius = 20
        emailField.delegate = self
        passwordField.delegate = self
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    func alerUserLoginError(){
        let alert = UIAlertController(title: "Woops", message: "Please enter all information to login ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
        
    }
    func alertUserVerified(){
        let alert = UIAlertController(title: "Wait !!!", message: "Please verify your email address before login. Check your email for vefication link ", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField
        { case emailField :
            passwordField.becomeFirstResponder()
        case passwordField :
            textField.resignFirstResponder()
        default :
            textField.resignFirstResponder()
        }
        return true
    }
}





