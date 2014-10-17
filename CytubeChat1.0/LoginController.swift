//
//  LoginController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/16/14.
//  Copyright (c) 2014 Tracy Cage Industries. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
    
    @IBOutlet var usernameText:UITextField!
    @IBOutlet var passwordText:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitBtnClicked(btn:UIBarButtonItem) {
        var room = roomMng.getActiveRoom()
        let username:String = usernameText.text
        let password:String = passwordText.text
        self.dismissViewControllerAnimated(true, completion: nil)
        room?.setUsername(usernameText.text)
        room?.setPassword(password)
        room?.sendLogin()
    }
}