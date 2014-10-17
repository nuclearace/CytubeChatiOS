//
//  ThirdViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class ChatWindowController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var roomTitle:UINavigationItem!
    @IBOutlet var messageView:UITableView!
    @IBOutlet var chatInput:UITextField!
    let tapRec = UITapGestureRecognizer()
    weak var room:CytubeRoom?
    var loggedIn:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        room = roomMng.getActiveRoom()
        room?.setChatWindow(self)
        roomTitle.title = room?.roomName
        tapRec.addTarget(self, action: "tappedMessages")
        messageView.addGestureRecognizer(tapRec)
        messageView.reloadData()
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let r:CytubeRoom = room? {
            var c = room?.messageBuffer.count
            return c!
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
        
        var font = UIFont(name: "Helvetica Neue", size: 12)
        // println(room?.messageBuffer.objectAtIndex(1))
        cell.textLabel?.font = font
        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.text = room?.messageBuffer.objectAtIndex(indexPath.row) as NSString
        
        return cell
    }
    
    //    func keyboardWillShow(sender: NSNotification) {
    //        self.view.frame.origin.y -= posOfChatInput
    //    }
    //
    //    func keyboardWillHide(sender: NSNotification) {
    //        self.view.frame.origin.y += posOfChatInput
    //    }
    
    // Hide keyboard if we touch anywhere
    func tappedMessages() {
        self.view.endEditing(true)
        messageView.reloadData()
    }
    
    override func touchesBegan(touches:NSSet, withEvent event:UIEvent) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        println("got enter")
        let msg = chatInput.text
        room?.sendChatMsg(msg)
        chatInput.text = nil
        textField.resignFirstResponder()
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func scrollChat(index:Int) {
        var indexPath:NSIndexPath = NSIndexPath(forItem: index - 1, inSection: 0)
        messageView.reloadData()
        messageView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
}