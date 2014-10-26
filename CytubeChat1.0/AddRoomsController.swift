//
//  SecondViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class AddRoomsController: UIViewController {
    
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
    
    // Add room was pressed
    @IBAction func btnAddTask(sender: UIButton) {
        let room = roomText.text
        let server = serverText.text
        var password = passwordText.text
        
        if (server == "" || room == "") {
            CytubeUtils.displayGenericAlertWithNoButtons("Error", message: "Please enter a valid server and room.")
            return
        }
        
        let cRoom = roomMng.findRoom(room, server: server)
        
        // User is trying to add an existing room
        if (cRoom != nil) {
            CytubeUtils.displayGenericAlertWithNoButtons("Already added", message: "You have already added this room!")
            return
        }
        var newRoom = CytubeRoom(roomName: room, server: server, password: password)
        roomMng.addRoom(server, room: room, cytubeRoom: newRoom)
        
        self.view.endEditing(true)
        serverText.reloadInputViews()
        roomText.text = nil
        passwordText.text = nil
        roomMng.saveRooms()
        self.tabBarController?.selectedIndex = 0
        
        if (!NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce")) {
            CytubeUtils.displayGenericAlertWithNoButtons("Hint", message: "You can long press on a room to bring up options for that room." +
                "Alternativly you can swipe left on a row to bring up a delete option")
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    override func touchesBegan(touches:NSSet, withEvent event:UIEvent) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

