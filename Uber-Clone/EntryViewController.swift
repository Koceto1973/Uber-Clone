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
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.isHidden  = true
        infoLabel.text = ""
        driverLabel.layer.borderColor = UIColor.green.cgColor
        riderLabel.layer.borderColor = UIColor.green.cgColor
        driverLabel.layer.borderWidth = 2.0
        riderLabel.layer.borderWidth = 0.0
        
        // keyboard return
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    @IBAction func switchClicked(_ sender: Any) {
        if riderOrDriverSwitch.isOn {
            driverLabel.layer.borderWidth = 2.0
            riderLabel.layer.borderWidth = 0.0
        } else {
            driverLabel.layer.borderWidth = 0.0
            riderLabel.layer.borderWidth = 2.0
        }
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
                            if self.riderOrDriverSwitch.isOn {
                                // DRIVER
                                let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                req?.displayName = "Driver"
                                req?.commitChanges(completion: nil)
                                self.performSegue(withIdentifier: "driverSegue", sender: nil)
                            } else {
                                // RIDER
                                let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                req?.displayName = "Rider"
                                req?.commitChanges(completion: nil)
                                self.performSegue(withIdentifier: "riderSegue", sender: nil)
                            }
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
                            if user?.user.displayName == "Driver" {
                            // DRIVER
                                self.performSegue(withIdentifier: "driverSegue", sender: nil)
                            } else {
                                // RIDER
                                self.performSegue(withIdentifier: "riderSegue", sender: nil)
                            }
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








