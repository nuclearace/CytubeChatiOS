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
        var version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
        var versionInt:Int? = version.toInt()
        let room = roomText.text
        let server = serverText.text
        var password = passwordText.text
        
        if (server == "" || room == "") {
            if (versionInt < 8) {
                var errorMessage = UIAlertView(title: "Error", message: "Please enter a valid server and room.", delegate: nil, cancelButtonTitle: "Return")
                return errorMessage.show()
            } else {
                var alert = UIAlertController(title: "Error", message: "Please enter a valid server and room.", preferredStyle: UIAlertControllerStyle.Alert)
                var action = UIAlertAction(title: "Return", style: UIAlertActionStyle.Default, handler: nil)
                alert.addAction(action)
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
        }
//        if (server == "cytu.be" || server == "synchtu.be" || server == "milkbartube.com") {} else {
//            if (versionInt < 8) {
//                var errorMessage = UIAlertView(title: "Unsupported Server", message: "Only connections to cytu.be and synchtu.be are supported in this version.", delegate: nil, cancelButtonTitle: "Return")
//                return errorMessage.show()
//            } else {
//                var alert = UIAlertController(title: "Unsupported Server", message: "Only connections to cytu.be and synchtu.be are supported in this version.", preferredStyle: UIAlertControllerStyle.Alert)
//                var action = UIAlertAction(title: "Return", style: UIAlertActionStyle.Default, handler: nil)
//                alert.addAction(action)
//                self.presentViewController(alert, animated: true, completion: nil)
//                return
//            }
//        }
        let cRoom = roomMng.findRoom(room, server: server)
        
        // User is trying to add an existing room
        if (cRoom != nil) {
            return println("Error Trying to add existing room")
        }
        var newRoom = CytubeRoom(roomName: room, server: server, password: password)
        roomMng.addRoom(server, room: room, cytubeRoom: newRoom)
        
        self.view.endEditing(true)
        serverText.reloadInputViews()
        roomText.text = nil
        passwordText.text = nil
        roomMng.saveRooms()
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

