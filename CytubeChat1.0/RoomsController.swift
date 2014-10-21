//
//  FirstViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class RoomsController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate  {
    
    @IBOutlet var tblRoom:UITableView!
    var inAlert:Bool = false
    var selectedRoom:CytubeRoom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated:Bool) {
        tblRoom.reloadData()
        var room = roomMng.getActiveRoom()
        room?.setChatWindow(nil)
        room?.setActive(false)
    }
    
    @IBAction func didLongPress(sender:UIGestureRecognizer) {
        if (self.inAlert) {
            return
        }
        self.inAlert = true
        var version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
        var versionInt:Int? = version.toInt()
        var point = sender.locationInView(tblRoom)
        var indexPath = tblRoom.indexPathForRowAtPoint(point)
        var room:CytubeRoom!
        
        if (indexPath != nil && versionInt >= 8) {
            self.selectedRoom = roomMng.getRoomAtIndex(indexPath!.row)
            var alert = UIAlertController(title: "Options", message: "What do you want to do?", preferredStyle: UIAlertControllerStyle.Alert)
            var action = UIAlertAction(title: "Disconnect", style: UIAlertActionStyle.Default) {[weak self] (action:UIAlertAction?) in
                self?.selectedRoom.closeRoom()
                self?.inAlert = false
                self?.selectedRoom = nil
            }
            
            var action1 = UIAlertAction(title: "Remove", style: UIAlertActionStyle.Destructive) {[weak self] (action:UIAlertAction?) in
                self?.selectedRoom.handleImminentDelete()
                self?.inAlert = false
                self?.selectedRoom = nil
            }

            alert.addAction(action)
            alert.addAction(action1)
            self.presentViewController(alert, animated: true, completion: nil)
        } else if (indexPath != nil) {
            self.selectedRoom = roomMng.getRoomAtIndex(indexPath!.row)
            var alert:UIAlertView = UIAlertView(title: "Options", message: "What do you want to do?",
                delegate: self, cancelButtonTitle: "Cancel")
            alert.addButtonWithTitle("Disconnect")
            alert.addButtonWithTitle("Remove")
            alert.show()
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1 && selectedRoom.isConnected()) {
            self.selectedRoom.closeRoom()
        } else if (buttonIndex == 2) {
            self.selectedRoom.handleImminentDelete()
        }
        self.selectedRoom = nil
        self.inAlert = false
    }
    
    // Called when a selects a room
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var room = roomMng.getRoomAtIndex(indexPath.row)
        if (!room.isConnected()) {
            room.openSocket()
        }
        room.setActive(true)
        self.performSegueWithIdentifier("goToChatRoom", sender: self)
    }
    
    // This will remove a room
    func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        var roomToDelete = roomMng.getRoomAtIndex(indexPath.row)
        if (roomToDelete.isConnected() && editingStyle == UITableViewCellEditingStyle.Delete) {
            roomToDelete.handleImminentDelete()
        } else if (!roomToDelete.isConnected()){
            roomMng.removeRoom(indexPath.row)
        }
    }
    
    // Tells how many rows to redraw
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomMng.rooms.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:
        NSIndexPath) -> UITableViewCell {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "roomsCell")
            
            roomMng.rooms[indexPath.row].cytubeRoom.setView(self)
            cell.textLabel?.text = roomMng.rooms[indexPath.row].room
            cell.detailTextLabel?.text = roomMng.rooms[indexPath.row].server
            
            return cell
    }
}

