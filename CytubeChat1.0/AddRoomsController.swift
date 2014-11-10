//
//  AddRoomsController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class AddRoomsController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var serverText:UITextField!
    @IBOutlet weak var roomText:UITextField!
    @IBOutlet weak var passwordText:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Add room was pressed
    @IBAction func btnAddTask(sender: UIButton) {
        self.handleAddRoom()
    }
    
    func handleAddRoom() {
        let room = roomText.text
        let server = serverText.text
        let password = passwordText.text
        
        if (server == "" || room == "") {
            CytubeUtils.displayGenericAlertWithNoButtons("Error", message:
                "Please enter a valid server and room.", view: self)
            return
        }
        
        // User is trying to add an existing room
        if let cRoom = roomMng.findRoom(room, server: server) {
            CytubeUtils.displayGenericAlertWithNoButtons("Already added", message:
                "You have already added this room!", view: self)
            return
        }
        var newRoom = CytubeRoom(roomName: room, server: server, password: password)
        roomMng.addRoom(server, room: room, cytubeRoom: newRoom)
        
        self.view.endEditing(true)
        self.serverText.reloadInputViews()
        self.roomText.text = nil
        self.passwordText.text = nil
        roomMng.saveRooms()
        self.tabBarController?.selectedIndex = 0
        
        if (!NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce")) {
            CytubeUtils.displayGenericAlertWithNoButtons("Hint",
                message: "Click on a room to join it." +
                " You can also long press on a room to bring up options for that room.", view: self)
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    override func touchesBegan(touches:NSSet, withEvent event:UIEvent) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        self.handleAddRoom()
        return true
    }
}

