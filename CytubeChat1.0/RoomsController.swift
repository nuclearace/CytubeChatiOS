//
//  RoomsController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class RoomsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate  {
    
    @IBOutlet weak var tblRoom:UITableView!
    var inAlert:Bool = false
    var selectedRoom:CytubeRoom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultCenter.addObserverForName("roomRemoved", object: nil, queue: nil) {[unowned self] not in
                self.tblRoom.reloadData()
        }
        defaultCenter.addObserver(self, selector: "handleSocketURLFail:",
            name: "socketURLFail", object: nil)
    }
    
    override func viewDidAppear(animated:Bool) {
        tblRoom.reloadData()
        var room = roomMng.getActiveRoom()
        room?._setChatWindow(nil)
        room?.active = false
    }
    
    deinit {
        defaultCenter.removeObserver(self)
    }
    
    @IBAction func didLongPress(sender:UIGestureRecognizer) {
        if self.inAlert {
            return
        }
        
        self.inAlert = true
        let point = sender.locationInView(tblRoom)
        let indexPath = tblRoom.indexPathForRowAtPoint(point)
        if indexPath == nil {
            self.inAlert = false
            return
        }
        
        self.selectedRoom = roomMng.getRoomAtIndex(indexPath!.row)
        var connectDisconnect:String!
        let connected = selectedRoom.isConnected()
        if connected {
            connectDisconnect = "Disconnect"
        } else {
            connectDisconnect = "Connect"
        }
        var alert = UIAlertController(title: "Options", message: "What do you want to do?",
            preferredStyle: UIAlertControllerStyle.Alert)
        var action = UIAlertAction(title: connectDisconnect, style: UIAlertActionStyle.Default) {[weak self] action in
            if connected {
                self?.selectedRoom.closeRoom()
                self?.inAlert = false
                self?.selectedRoom = nil
            } else {
                if !(self?.selectedRoom.isConnected())! {
                    self?.selectedRoom.openSocket()
                }
                
                self?.selectedRoom.active = true
                self?.inAlert = false
                self?.selectedRoom = nil
                self?.performSegueWithIdentifier("goToChatRoom", sender: self)
            }
        }
        
        var action1 = UIAlertAction(title: "Remove", style: UIAlertActionStyle.Destructive) {[weak self] action in
            self?.selectedRoom.handleImminentDelete()
            self?.inAlert = false
            self?.selectedRoom = nil
        }
        var action2 = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {[weak self] action in
            self?.inAlert = false
            self?.selectedRoom = nil
        }
        
        alert.addAction(action)
        alert.addAction(action1)
        alert.addAction(action2)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 && selectedRoom.isConnected() {
            self.selectedRoom.closeRoom()
        } else if (buttonIndex == 1 && !selectedRoom.isConnected()) {
            if !selectedRoom.isConnected() {
                selectedRoom.openSocket()
            }
            selectedRoom.active = true
            self.performSegueWithIdentifier("goToChatRoom", sender: self)
        } else if buttonIndex == 2 {
            self.selectedRoom.handleImminentDelete()
        }
        
        self.selectedRoom = nil
        self.inAlert = false
    }
    
    // Called when a user selects a room
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var room = roomMng.getRoomAtIndex(indexPath.row)
        room.active = true
        self.performSegueWithIdentifier("goToChatRoom", sender: self)
    }
    
    // Tells how many rows to redraw
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomMng.rooms.count
    }
    
    // Creates cells
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:
        NSIndexPath) -> UITableViewCell {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "roomsCell")
            
            roomMng.rooms[indexPath.row].cytubeRoom.roomsController = self
            cell.textLabel?.text = roomMng.rooms[indexPath.row].room
            cell.detailTextLabel?.text = roomMng.rooms[indexPath.row].server
            return cell
    }
    
    func handleSocketURLFail(not:NSNotification) {
        CytubeUtils.displayGenericAlertWithNoButtons(title: "Socket Failure",
            message: "Failed to load socketURL. Check you entered" +
            " the server correctly", view: self)
    }
}

