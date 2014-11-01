//
//  ThirdViewController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class ChatWindowController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var roomTitle:UIButton!
    @IBOutlet weak var messageView:UITableView!
    @IBOutlet weak var chatInput:UITextField!
    @IBOutlet weak var loginButton:UIBarButtonItem!
    @IBOutlet weak var inputBottomLayoutGuide:NSLayoutConstraint!
    var canScroll:Bool = true
    let tapRec = UITapGestureRecognizer()
    weak var room:CytubeRoom?
    var loggedIn:Bool = false
    var keyboardOffset:CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"),
            name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"),
            name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("wasKicked:"),
            name: "wasKicked", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("passwordFail:"),
            name: "passwordFail", object: nil)
        room = roomMng.getActiveRoom()
        if (self.room != nil) {
            if (room!.loggedIn) {
                loginButton.enabled = false
                chatInput.enabled = true
            }
        }
        room?.setChatWindow(self)
        roomTitle.setTitle(room?.roomName, forState: nil)
        tapRec.addTarget(self, action: "tappedMessages")
        messageView.addGestureRecognizer(tapRec)
        messageView.estimatedRowHeight = 40.0
        messageView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        messageView.reloadData()
        if (self.room != nil) {
            self.scrollChat(self.room!.messageBuffer.count)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.canScroll = false
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.canScroll = true
    }
    
    func keyboardWillShow(not:NSNotification) {
        var scrollNum = room?.messageBuffer.count
        var info = not.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        self.keyboardOffset = self.inputBottomLayoutGuide.constant
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            self.inputBottomLayoutGuide.constant = keyboardFrame.size.height + 10
        })
        self.scrollChat(scrollNum!)
    }
    
    func keyboardWillHide(not:NSNotification) {
        var info = not.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        //self.keyboardOffset = self.inputBottomLayoutGuide.constant
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            self.inputBottomLayoutGuide.constant = self.keyboardOffset
        })
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
        let cell:UITableViewCell = messageView.dequeueReusableCellWithIdentifier("chatWindowCell") as UITableViewCell
        let font = UIFont(name: "Helvetica Neue", size: 12)
        
        (cell.contentView.subviews[0] as UITextView).font = font
        (cell.contentView.subviews[0] as UITextView).text = nil
        (cell.contentView.subviews[0] as UITextView).text = room?.messageBuffer.objectAtIndex(indexPath.row) as NSString
        return cell
    }
    
    // Hide keyboard if we touch anywhere
    func tappedMessages() {
        self.view.endEditing(true)
        messageView.reloadData()
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        let msg = chatInput.text
        room?.sendChatMsg(msg)
        chatInput.text = nil
        return false
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.room?.setChatWindow(nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func scrollChat(index:Int) {
        if (!self.canScroll || index == 0) {
            return
        }
        var indexPath:NSIndexPath = NSIndexPath(forItem: index - 1, inSection: 0)
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue(), {[weak self]() in
            if (self != nil) {
                self?.messageView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        })
    }
    
    func wasKicked(not:NSNotification) {
        let version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
        let versionInt:Int? = version.toInt()
        let roomName = self.room!.roomName
        let reason = not.object as NSString
        
        if (versionInt < 8) {
            var alert:UIAlertView = UIAlertView(title: "Kicked", message:
                "You have been kicked from room \(roomName). Reason: \(reason)",
                delegate: self, cancelButtonTitle: "Okay")
            alert.show()
        } else {
            var alert = UIAlertController(title: "Kicked", message:
                "You have been kicked from room \(roomName). Reason: \(reason)", preferredStyle: UIAlertControllerStyle.Alert)
            var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {(action:UIAlertAction?) in
                self.room?.setChatWindow(nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func passwordFail(not:NSNotification) {
        let version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
        let versionInt:Int? = version.toInt()
        let roomName = self.room!.roomName
        
        if (versionInt < 8) {
            var alert:UIAlertView = UIAlertView(title: "Password Fail", message:
                "No password, or incorrect password for: \(roomName). Please try adding again.",
                delegate: self, cancelButtonTitle: "Okay")
            alert.show()
        } else {
            var alert = UIAlertController(title: "Password Fail", message:
                "No password, or incorrect password for: \(roomName). Please try adding again.",
                preferredStyle: UIAlertControllerStyle.Alert)
            var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {(action:UIAlertAction?) in
                self.room?.setChatWindow(nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}