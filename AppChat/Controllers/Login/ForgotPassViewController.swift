//
//  ForgotPassViewController.swift
//  AppChat
//
//  Created by Trung on 05/06/2023.
//

import UIKit
import FirebaseAuth
class ForgotPasswordViewController: UIViewController,UITextFieldDelegate {
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var emailField: UITextField!
    
    
    @IBOutlet weak var sendButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        // Do any additional setup after loading the view.
        emailField.delegate = self
        let systemBackgroundColor = UIColor.systemBackground
        label.layer.borderWidth = 2
        label.layer.cornerRadius = 25
        label.layer.borderColor = UIColor.secondarySystemBackground.cgColor
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        emailField.resignFirstResponder()
        Auth.auth().sendPasswordReset(withEmail: emailField.text!, completion: {
            error in
            if let error = error {
                let alert = UIAlertController(title: "Failed to send", message: "\(error.localizedDescription)", preferredStyle: .alert)
                let alertOK = UIAlertAction(title: "Try Again", style: .default, handler: nil)
                let alertCancel = UIAlertAction(title: "Cancel", style: .destructive, handler: {acting in
                    self.emailField.text = ""
                })
                alert.addAction(alertOK)
                alert.addAction(alertCancel)
                self.present(alert, animated: true)
            }
            else {
                let alert = UIAlertController(title: "Success", message: "An email has been sent, please check it !!!", preferredStyle: .actionSheet)
                let alertOK = UIAlertAction(title: "OKe", style: .default, handler: nil)
                alert.addAction(alertOK)
                self.present(alert, animated: true)
            }
        })
        
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailField.resignFirstResponder()
        return true
    }
}
