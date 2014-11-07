//
//  UserlistController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/20/14.
//

import UIKit

class UserlistController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userlistTitle:UINavigationItem!
    @IBOutlet weak var tblUserlist:UITableView!
    weak var room:CytubeRoom!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        room = roomMng.getActiveRoom()
        userlistTitle.title = room.roomName + " userlist"
        room.setUserlistView(self)
        tblUserlist.reloadData()
    }
    
    override func viewDidDisappear(animated: Bool) {
        room.setUserlistView(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return room.userlist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:
        NSIndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "userlistCell")
            let user = room!.userlist[indexPath.row]
            
            cell.textLabel.attributedText = user.createAttributedStringForUser()
            return cell
            
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}