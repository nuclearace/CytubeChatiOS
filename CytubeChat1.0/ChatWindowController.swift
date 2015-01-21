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
    var keyboardIsShowing = false
    var loggedIn:Bool = false
    var keyboardOffset:CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.room = roomMng.getActiveRoom()
        if self.room != nil {
            if (room!.loggedIn) {
                self.loginButton.enabled = false
                self.chatInput.enabled = true
            }
        }
        self.room?.setChatWindow(self)
        self.roomTitle.setTitle(self.room?.roomName, forState: nil)
        self.tapRec.addTarget(self, action: "tappedMessages")
        self.messageView.addGestureRecognizer(self.tapRec)
    }
    
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(true)
        
        defaultCenter.addObserver(self, selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification, object: nil)
        defaultCenter.addObserver(self, selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification, object: nil)
        defaultCenter.addObserver(self, selector: "wasKicked:",
            name: "wasKicked", object: nil)
        defaultCenter.addObserver(self, selector: "passwordFail:",
            name: "passwordFail", object: nil)
        defaultCenter.addObserver(self, selector: "handleNilSocketURL:",
            name: "nilSocketURL", object: nil)
        defaultCenter.addObserver(self, selector: "handleNoInternet:",
            name: "noInternet", object: nil)
        defaultCenter.addObserver(self, selector: "handleSocketURLFail:",
            name: "socketURLFail", object: nil)
        defaultCenter.addObserver(self, selector: "handleSocketTimeout:",
            name: "socketTimeout", object: nil)
        
        if self.room.kicked {
            self.wasKicked(NSNotification(name: "wasKicked", object: [
                "room": self.room.roomName,
                "reason": ""
                ]))
        }
        
        self.scrollChat()
        // Start connection to server
        if !self.room.isConnected() {
            self.room.openSocket()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        defaultCenter.removeObserver(self)
    }
    
    deinit {
        defaultCenter.removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if let segueIdentifier = segue.identifier {
            if segueIdentifier == "openChatLink" {
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
        if self.keyboardIsShowing {
            return
        }
        self.keyboardIsShowing = true
        self.canScroll = true
        let scrollNum = room?.messageBuffer.count
        let info = not.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        self.keyboardOffset = self.inputBottomLayoutGuide.constant
        UIView.animateWithDuration(0.3, animations: {() -> Void in
            self.inputBottomLayoutGuide.constant = keyboardFrame.size.height + 10
        })
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0.01))
        
        dispatch_after(time, dispatch_get_main_queue()) {self.scrollChat()}
    }
    
    func keyboardWillHide(not:NSNotification) {
        self.canScroll = true
        self.keyboardIsShowing = false
        
        UIView.animateWithDuration(0.3, animations: {[unowned self] () -> Void in
            self.inputBottomLayoutGuide.constant = self.keyboardOffset
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if room != nil {
            return room!.messageBuffer.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath:NSIndexPath) -> CGFloat {
        return self.heightForRowAtIndexPath(indexPath)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = messageView.dequeueReusableCellWithIdentifier("chatWindowCell") as UITableViewCell
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
        if !self.canScroll || self.room?.messageBuffer.count == 0 {
            return
        }
        
        self.messageView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.room.messageBuffer.count - 1, inSection: 0),
            atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
    
    func handleNilSocketURL(not:NSNotification) {
        CytubeUtils.displayGenericAlertWithNoButtons(title: "Connection Failed",
            message: "Could not connect to server, check you are connected to the internet", view: self)
    }
    
    func handleNoInternet(not:NSNotification) {
        CytubeUtils.displayGenericAlertWithNoButtons(title: "No Internet",
            message: "Check your internet connection", view: self)
    }
    
    func handleSocketURLFail(not:NSNotification) {
        CytubeUtils.displayGenericAlertWithNoButtons(title: "Socket Failure", message: "Failed to load socketURL. Check you entered" +
            " the server correctly", view: self)
    }
    
    func handleSocketTimeout(not:NSNotification) {
        CytubeUtils.displayGenericAlertWithNoButtons(title: "Timeout", message: "It is taking too long to connect." +
            "The server may be having trouble, or your connection is poor.", view: self)
    }
    
    func wasKicked(not:NSNotification) {
        let roomName = self.room!.roomName
        let kickObj = not.object as NSDictionary
        
        if kickObj["room"] as? String != roomName {
            return
        }
        
        self.chatInput.resignFirstResponder()
        let reason = kickObj["reason"] as String
        
        var alert = UIAlertController(title: "Kicked", message:
            "You have been kicked from room \(roomName). Reason: \(reason)", preferredStyle: UIAlertControllerStyle.Alert)
        var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {action in
            self.room?.setChatWindow(nil)
            self.room?.closeRoom()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func passwordFail(not:NSNotification) {
        let roomName = self.room!.roomName
        var alert = UIAlertController(title: "Password Fail", message:
            "No password, or incorrect password for: \(roomName). Please try adding again.",
            preferredStyle: UIAlertControllerStyle.Alert)
        var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {action in
            self.room?.setChatWindow(nil)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(action)
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}