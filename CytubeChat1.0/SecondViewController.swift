//
//  SecondViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//  Copyright (c) 2014 Tracy Cage Industries. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    
    @IBOutlet var serverText:UITextField!
    @IBOutlet var roomText:UITextField!
    @IBOutlet var passwordText:UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Join room was pressed
    @IBAction func btnAddTask(sender: UIButton) {
        roomMng.addRoom(serverText.text, room: roomText.text, cytubeRoom: CytubeRoom())
        self.view.endEditing(true)
        serverText.reloadInputViews()
        roomText.text = nil
        passwordText.text = nil
        self.tabBarController?.selectedIndex = 0
    }
    
    override func touchesBegan(touches:NSSet, withEvent event:UIEvent) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

