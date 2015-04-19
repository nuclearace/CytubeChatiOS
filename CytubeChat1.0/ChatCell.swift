//
//  ChatCell.swift
//  CytubeChat
//
//  Created by Erik Little on 11/8/14.
//

import UIKit

class ChatCell: UITableViewCell, UITextViewDelegate {
    var link:NSURL!
    
    func textView(textView:UITextView, shouldInteractWithURL URL:NSURL, inRange characterRange:NSRange) -> Bool {
        self.link = URL
        ((self.superview!.superview! as! UITableView).dataSource as! ChatWindowController)
            .performSegueWithIdentifier("openChatLink", sender: self)
        return false
    }
}
