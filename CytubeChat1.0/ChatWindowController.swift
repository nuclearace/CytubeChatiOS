//
//  ChatWindowController.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

private let sizingView = UITextView()

class ChatWindowController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var roomTitle:UIButton!
    @IBOutlet weak var messageView:UITableView!
    @IBOutlet weak var chatInput:UITextField!
    @IBOutlet weak var loginButton:UIBarButtonItem!
    @IBOutlet weak var inputBottomLayoutGuide:NSLayoutConstraint!
    weak var room:CytubeRoom!
    let tapRec = UITapGestureRecognizer()
    var canScroll:Bool = true
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
        self.room = roomMng.getActiveRoom()
        if (self.room != nil) {
            if (room!.loggedIn) {
                loginButton.enabled = false
                chatInput.enabled = true
            }
        }
        self.room?.setChatWindow(self)
        self.roomTitle.setTitle(room?.roomName, forState: nil)
        self.tapRec.addTarget(self, action: "tappedMessages")
        self.messageView.addGestureRecognizer(tapRec)
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(true)
        self.scrollChat()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if let segueIdentifier = segue.identifier {
            if (segueIdentifier == "openChatLink") {
                let cell = sender as ChatCell
                (segue.destinationViewController as ChatLinkController).link = cell.link
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.canScroll = false
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.canScroll = true
    }
    
    func keyboardWillShow(not:NSNotification) {
        self.canScroll = true
        let scrollNum = room?.messageBuffer.count
        let info = not.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        self.keyboardOffset = self.inputBottomLayoutGuide.constant
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            self.inputBottomLayoutGuide.constant = keyboardFrame.size.height + 10
        })
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.01))
        dispatch_after(time, dispatch_get_main_queue()) {() in
            self.scrollChat()
        }
    }
    
    func keyboardWillHide(not:NSNotification) {
        self.canScroll = true
        let info = not.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.3, animations: {[unowned self] () -> Void in
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return self.heightForRowAtIndexPath(indexPath)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = messageView.dequeueReusableCellWithIdentifier("chatWindowCell") as UITableViewCell
        let font = UIFont(name: "Helvetica Neue", size: 12)
        (cell.contentView.subviews[0] as UITextView).font = font
        (cell.contentView.subviews[0] as UITextView).text = nil
        (cell.contentView.subviews[0] as UITextView).attributedText =
            self.room?.messageBuffer.objectAtIndex(indexPath.row) as NSMutableAttributedString
        
        return cell
    }
    
    func heightForRowAtIndexPath(indexPath:NSIndexPath) -> CGFloat {
        sizingView.attributedText = room?.messageBuffer.objectAtIndex(indexPath.row)
            as NSMutableAttributedString
        
        let width = self.messageView.frame.size.width
        let size = sizingView.sizeThatFits(CGSizeMake(width, 120.0))
        
        return size.height + 3 // Need some padding
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
        self.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func scrollChat() {
        if (!self.canScroll || self.room?.messageBuffer.count == 0) {
            return
        }
        
        self.messageView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.room.messageBuffer.count - 1, inSection: 0),
            atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    func wasKicked(not:NSNotification) {
        let version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
        let versionInt:Int? = version.toInt()
        let roomName = self.room!.roomName
        let kickObj = not.object as NSDictionary
        if (kickObj["room"] as NSString != roomName) {
            return
        }
        let reason = kickObj["reason"] as NSString
        
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