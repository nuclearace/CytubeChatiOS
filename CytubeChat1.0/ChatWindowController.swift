//
//  ThirdViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class ChatWindowController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var roomTitle:UIButton!
    @IBOutlet var messageView:UITableView!
    @IBOutlet var chatInput:UITextField!
    @IBOutlet var loginButton:UIBarButtonItem!
    @IBOutlet var inputBottomLayoutGuide:NSLayoutConstraint!
    let tapRec = UITapGestureRecognizer()
    weak var room:CytubeRoom?
    var loggedIn:Bool = false
    var keyboardOffset:CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        room = roomMng.getActiveRoom()
        if ((room?.loggedIn) != nil) {
            if (room!.loggedIn) {
                loginButton.enabled = false
                chatInput.enabled = true
            }
        }
        room?.setChatWindow(self)
        roomTitle.setTitle(room?.roomName, forState: nil)
        tapRec.addTarget(self, action: "tappedMessages")
        messageView.addGestureRecognizer(tapRec)
        messageView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Default")
        
        var font = UIFont(name: "Helvetica Neue", size: 12)
        // println(room?.messageBuffer.objectAtIndex(1))
        cell.textLabel?.font = font
        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.text = room?.messageBuffer.objectAtIndex(indexPath.row) as NSString
        
        return cell
    }
    
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
        // textField.resignFirstResponder()
        return false
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.room?.setChatWindow(nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func scrollChat(index:Int) {
        var indexPath:NSIndexPath = NSIndexPath(forItem: index - 1, inSection: 0)
        messageView.reloadData()
        messageView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }
}