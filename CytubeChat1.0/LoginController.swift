//
//  LoginController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/16/14.
//

import UIKit

class LoginController: UIViewController {
    
    @IBOutlet weak var usernameText:UITextField!
    @IBOutlet weak var passwordText:UITextField!
    var room:CytubeRoom?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        room = roomMng.getActiveRoom()
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitBtnClicked(btn:UIBarButtonItem) {
        self.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
        let username:String = usernameText.text
        let password:String = passwordText.text
        room?.setUsername(usernameText.text)
        room?.setPassword(password)
        room?.sendLogin()
    }
}