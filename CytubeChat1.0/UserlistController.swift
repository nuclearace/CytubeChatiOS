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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.room = roomMng.getActiveRoom()
        self.userlistTitle.title = room.roomName + " userlist"
        self.room.setUserlistView(self)
        self.tblUserlist.reloadData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.room.setUserlistView(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.room.userlist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:
        NSIndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "userlistCell")
            let user = self.room.userlist[indexPath.row]
            
            cell.textLabel?.attributedText = user.createAttributedStringForUser()
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedUser = self.room.userlist[indexPath.row]
        if (self.selectedUser.username == self.room.username?) {
            return
        }
        self.showIgnoreUserAlert(user: self.selectedUser)
    }
    
    func showIgnoreUserAlert(#user:CytubeUser) {
        let version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
        let versionInt:Int? = version.toInt()
        var title:String!
        var message:String!
        if (CytubeUtils.userIsIgnored(ignoreList: self.room.ignoreList, user: user)) {
            title = "Unignore"
            message = "Unignore \(user.getUsername())?"
        } else {
            title = "Ignore"
            message = "Ignore \(user.getUsername())?"
        }
        
        if (versionInt >= 8) {
            var alert = UIAlertController(title: title, message:
                message, preferredStyle: UIAlertControllerStyle.Alert)
            var yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default) {alert in
                if (title == "Unignore") {
                    for (var i = 0; i < self.room.ignoreList.count; ++i) {
                        if (self.room.ignoreList[i] == self.selectedUser.getUsername()) {
                            self.room.ignoreList.removeAtIndex(i)
                        }
                    }
                } else {
                    self.room.ignoreList.append(self.selectedUser.getUsername())
                }
            }
            var noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel) {alert in
                return
            }
            alert.addAction(yesAction)
            alert.addAction(noAction)
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            var alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: "No")
            alert.addButtonWithTitle("Yes")
            alert.show()
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let title = alertView.title
        
        if (title == "Unignore" && buttonIndex == 1) {
            for (var i = 0; i < self.room.ignoreList.count; ++i) {
                if (self.room.ignoreList[i] == self.selectedUser.getUsername()) {
                    self.room.ignoreList.removeAtIndex(i)
                }
            }
        } else if (buttonIndex == 1) {
            self.room.ignoreList.append(self.selectedUser.getUsername())
        }
    }
}