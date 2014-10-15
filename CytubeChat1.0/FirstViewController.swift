//
//  FirstViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    @IBOutlet var tblRoom:UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated:Bool) {
        tblRoom.reloadData()
    }
    
    // Called when a selects a room
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("goToChatRoom", sender: self)
    }
    
    // This will remove a room
    func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            roomMng.getRoomAtIndex(indexPath.row).handleImminentDeleteShutdownSocket()
        }
    }

    // Tells how many rows to redraw
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return roomMng.rooms.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:
        NSIndexPath) -> UITableViewCell {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
            
            roomMng.rooms[indexPath.row].cytubeRoom.setView(self)
            cell.textLabel?.text = roomMng.rooms[indexPath.row].room
            cell.detailTextLabel?.text = roomMng.rooms[indexPath.row].server
            
            return cell
    }
}

