//
//  LoginController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/16/14.
//

import UIKit

class LoginController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameText:UITextField!
    @IBOutlet weak var passwordText:UITextField!
    var room:CytubeRoom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.room = roomMng.getActiveRoom()
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitBtnClicked(btn:UIBarButtonItem) {
        self.resignFirstResponder()
        self.handleLogin()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func handleLogin() {
        let username:String = usernameText.text
        let password:String = passwordText.text
        self.room?.setUsername(usernameText.text)
        self.room?.setPassword(password)
        self.room?.sendLogin()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        let nextTag = textField.tag + 1
        let nextResponder = textField.superview?.viewWithTag(nextTag)
        if (nextResponder != nil) {
            nextResponder!.becomeFirstResponder()
            return false
        }
        
        textField.resignFirstResponder()
        self.handleLogin()
        return true
    }
}