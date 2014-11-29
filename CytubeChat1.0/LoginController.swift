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
    var password:String!
    var username:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.room = roomMng.getActiveRoom()
        if (!NSUserDefaults.standardUserDefaults().boolForKey("HasLoggedIn")) {
            CytubeUtils.displayGenericAlertWithNoButtons(title: "Hint",
                message: "You can login as guest by submitting a username without a password.",
                view: self)
        }
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitBtnClicked(btn:UIBarButtonItem) {
        self.resignFirstResponder()
        self.username = usernameText.text
        self.password = passwordText.text
    }
    
    func handleLogin() {
        if (self.username == "") {
            CytubeUtils.displayGenericAlertWithNoButtons(title: "Invalid Username",
                message: "Username cannot be blank",
                view: self)
            return
        }
        self.handleLogin()
        self.room?.setUsername(self.username)
        self.room?.setPassword(self.password)
        self.room?.sendLogin()
        self.dismissViewControllerAnimated(true, completion: nil)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLoggedIn")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        let nextTag = textField.tag + 1
        let nextResponder = textField.superview?.viewWithTag(nextTag)
        if (nextResponder != nil) {
            nextResponder!.becomeFirstResponder()
            return false
        }
        
        self.username = usernameText.text
        self.password = passwordText.text
        textField.resignFirstResponder()
        self.handleLogin()
        return true
    }
}