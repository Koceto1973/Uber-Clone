//
//  ViewController.swift
//  Uber-Clone
//
//  Created by K.K. on 3.11.18.
//  Copyright © 2018 K.K. All rights reserved.
//

import UIKit
import FirebaseAuth

class EntryViewController: UIViewController, UITextFieldDelegate {
    
    //Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var riderOrDriverSwitch: UISwitch!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.isHidden  = true
        infoLabel.text = ""
        
        // keyboard return
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }

    @IBAction func SignUpPressed(_ sender: Any) {
        infoLabel.isHidden  = true
        infoLabel.text = ""
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            infoLabel.isHidden  = false
            infoLabel.text = "You must provide both a email and password"
        } else {
            if let email = emailTextField.text {
                if let password = passwordTextField.text {
                    Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                        if error != nil {
                            self.infoLabel.isHidden  = false
                            self.infoLabel.text = error!.localizedDescription
                        } else {
                            debugPrint("Sign Up Success")
                            self.performSegue(withIdentifier: "riderSegue", sender: nil)
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func LogInPressed(_ sender: Any) {
        infoLabel.isHidden  = true
        infoLabel.text = ""
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            infoLabel.isHidden  = false
            infoLabel.text = "You must provide both a email and password"
        } else {
            if let email = emailTextField.text {
                if let password = passwordTextField.text {
                    // LOG IN
                    Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                        if error != nil {
                            self.infoLabel.isHidden  = false
                            self.infoLabel.text = error!.localizedDescription
                        } else {
                            debugPrint("Log In Success")
                            self.performSegue(withIdentifier: "riderSegue", sender: nil)
                        }
                    })
                }
            }
        }
    }
    
    // text fields keybord management
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        infoLabel.isHidden  = true
        infoLabel.text = ""
    }
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        infoLabel.isHidden  = true
        infoLabel.text = ""
        return true
    }
    
}








