//
//  ThirdViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

class ThirdViewController: UIViewController {
    
    @IBOutlet var navRoom:UINavigationBar!
    @IBOutlet var messageView:UITextView!
    @IBOutlet var chatInput:UITextField!
    let tapRec = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("Loaded v3")
        tapRec.addTarget(self, action: "tappedMessages")
        messageView.addGestureRecognizer(tapRec)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    }
    
    override func touchesBegan(touches:NSSet, withEvent event:UIEvent) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField:UITextField) -> Bool {
        println("got enter")
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
    
    @IBAction func shouldSendMessage(btn:UIBarButtonItem) {
        println("Should send message")
    }
}