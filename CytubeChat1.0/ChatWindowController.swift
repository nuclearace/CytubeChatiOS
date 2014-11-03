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
    var userDidScrollUp = false
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
        self.messageView.estimatedRowHeight = 50.0
        self.messageView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(true)
        if (self.room != nil) {
            self.hackyScrollFix()
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
        self.userDidScrollUp = true
    }
    
    func keyboardWillShow(not:NSNotification) {
        var scrollNum = room?.messageBuffer.count
        var info = not.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        self.keyboardOffset = self.inputBottomLayoutGuide.constant
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            self.inputBottomLayoutGuide.constant = keyboardFrame.size.height + 10
        })
        self.scrollChat()
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
    
    func scrollChat() {
        let scrollViewHeight = self.messageView.frame.size.height
        let scrollContentSizeHeight = self.messageView.contentSize.height
        let scrollOffset = self.messageView.contentOffset.y
        let scrolledToBottom = (scrollOffset + scrollViewHeight) == scrollContentSizeHeight
        
        self.messageView.reloadData()
        if (!self.canScroll || self.room?.messageBuffer.count == 0) {
            return
        }
        if (self.userDidScrollUp && !scrolledToBottom) {
            self.userDidScrollUp = false
            self.hackyScrollFix()
            return
        }
        self.userDidScrollUp = false
        let indexPath:NSIndexPath = NSIndexPath(forRow: self.messageView.numberOfRowsInSection(0) - 1, inSection: 0)
        let delay = 0.1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(time, dispatch_get_main_queue(), {[weak self]() in
            if (self != nil) {
                self?.messageView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        })
    }
    
    // This fixes iOS 8's bug in auto cell height that caused scrolling to the bottom to overscroll
    func hackyScrollFix() {
        println("Performing hacky fix")
        if (self.room?.messageBuffer.count == 0) {
            return
        }
        
        let tempChat = self.room?.messageBuffer.copy() as [String]
        self.room?.messageBuffer.removeAllObjects()
        
        for msg in tempChat {
            self.room?.addMessageToChat(msg)
        }
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