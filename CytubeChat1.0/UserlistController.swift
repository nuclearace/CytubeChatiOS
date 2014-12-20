//
//  UserlistController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/20/14.
//

import UIKit

class UserlistController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
    
    @IBOutlet weak var userlistTitle:UINavigationItem!
    @IBOutlet weak var tblUserlist:UITableView!
    weak var room:CytubeRoom!
    weak var selectedUser:CytubeUser!
    var inAlert = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.room = roomMng.getActiveRoom()
        self.userlistTitle.title = room.roomName + " userlist"
        self.room.setUserlistView(self)
        self.tblUserlist.reloadData()
        if (!NSUserDefaults.standardUserDefaults().boolForKey("HasSeenUserlist")) {
            CytubeUtils.displayGenericAlertWithNoButtons(title: "Hint",
                message: "You can view a users profile by tapping on that user. Also, if that" +
                " user is annoying you, long press on their name to bring up options to ignore them.",
                view: self)
        }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasSeenUserlist")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.room.setUserlistView(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if let segueIdentifier = segue.identifier {
            if (segueIdentifier == "showProfile") {
                (segue.destinationViewController as ProfileViewController).user = self.selectedUser
            }
        }
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didLongPress(sender:UIGestureRecognizer) {
        if (self.inAlert) {
            return
        }
        self.inAlert = true
        let point = sender.locationInView(self.tblUserlist)
        let indexPath = self.tblUserlist.indexPathForRowAtPoint(point)
        if (indexPath == nil) {
            self.inAlert = false
            return
        }
        
        self.selectedUser = self.room.userlist[indexPath!.row]
        if (self.selectedUser.username.lowercaseString
            == self.room.username?.lowercaseString) {
                return
        }
        self.showIgnoreUserAlert(user: self.selectedUser)
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.room.userlist.count
    }
    
    func tableView(tableView:UITableView,
        cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "userlistCell")
            let user = self.room.userlist[indexPath.row]
            
            cell.textLabel?.attributedText = user.createAttributedStringForUser()
            return cell
    }
    
    func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        self.selectedUser = self.room.userlist[indexPath.row]
        if (self.selectedUser != nil) {
            self.performSegueWithIdentifier("showProfile", sender: self)
        }
    }
    
    func showIgnoreUserAlert(#user:CytubeUser) {
        var title:String!
        var message:String!
        if (CytubeUtils.userIsIgnored(ignoreList: self.room.ignoreList, user: user)) {
            title = "Unignore"
            message = "Unignore \(user.getUsername())?"
        } else {
            title = "Ignore"
            message = "Ignore \(user.getUsername())?"
        }
        
        var alert = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        var yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) {alert in
            if (title == "Unignore") {
                for (var i = 0; i < self.room.ignoreList.count; ++i) {
                    if (self.room.ignoreList[i] == self.selectedUser.getUsername()) {
                        self.room.ignoreList.removeAtIndex(i)
                    }
                }
                self.inAlert = false
            } else {
                self.room.ignoreList.append(self.selectedUser.getUsername())
                self.inAlert = false
            }
        }
        var noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel) {alert in
            self.inAlert = false
            return
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}