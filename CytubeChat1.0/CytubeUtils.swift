//
//  CytubeUtils.swift
//  CytubeChat
//
//  Created by Erik Little on 10/15/14.
//

import Foundation
import UIKit

class CytubeUtils {
    
    class func filterChatMsg(data:String) -> String {
        var mut = RegexMutable(data)
        mut = mut["(&#39;)"] ~= "'"
        mut = mut["(&amp;)"] ~= "&"
        mut = mut["(&lt;)"] ~= "<"
        mut = mut["(&gt;)"] ~= ">"
        mut = mut["(&quot;)"] ~= "\""
        mut = mut["(&#40;)"] ~= "("
        mut = mut["(&#41;)"] ~= ")"
        mut = mut["(<img[^>]+src\\s*=\\s*['\"]([^'\"]+)['\"][^>]*>)"] ~= "$2"
        mut = mut["(<([^>]+)>)"] ~= ""
        mut = mut["(^[ \t]+)"] ~= ""
        
        return mut as NSString
    }
    
    class func displayGenericAlertWithNoButtons(title:String, message:String, view:UIViewController?, completion:(() -> Void)?) {
        dispatch_async(dispatch_get_main_queue()) {() in
            let version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
            let versionInt:Int? = version.toInt()
            
            if (versionInt < 8) {
                var alert:UIAlertView = UIAlertView(title: title, message: message,
                    delegate: self, cancelButtonTitle: "Okay")
                alert.show()
            } else {
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {(action:UIAlertAction?) in
                    return
                }
                alert.addAction(action)
                if (view == nil) {
                    var view = UIApplication.sharedApplication().keyWindow?.rootViewController
                }
                view?.presentViewController(alert, animated: true, completion: nil)
            }
        }
        if (completion != nil) {
            completion!()
        }
    }
    
    class func userlistContainsUser(userlist:[CytubeUser], user:CytubeUser) -> Bool {
        for cuser in userlist {
            if (cuser.isEqual(user)) {
                return true
            }
        }
        return false
    }
    
    class func userIsIgnored(ignoreList:[CytubeUser], user:AnyObject) -> Bool {
        if (ignoreList.count == 0) {
            return false
        }
        
        for cuser in ignoreList {
            if let userAsCytubeUser = user as? CytubeUser {
                if (cuser.getUsername() == userAsCytubeUser.getUsername()) {
                    return true
                }
            } else if let userAsString = user as? NSString {
                if (cuser.getUsername() == userAsString) {
                    return true
                }
            }
        }
        return false
    }
    
    class func formatMessage(msgObj:NSDictionary) -> NSAttributedString {
        let time = msgObj["time"] as NSString
        let username = msgObj["username"] as NSString
        let msg = msgObj["msg"] as NSString
        let message = NSString(format: "%@ %@: %@", time, username, msg)
        let returnMessage = NSMutableAttributedString(string: message)
        let timeFont = UIFont(name: "Helvetica Neue", size: 10)
        let timeRange = message.rangeOfString(time)
        let usernameFont = UIFont.boldSystemFontOfSize(12)
        let usernameRange = message.rangeOfString(username + ":")
        
        returnMessage.addAttribute(kCTFontAttributeName, value: timeFont!, range: timeRange)
        returnMessage.addAttribute(kCTFontAttributeName, value: usernameFont, range: usernameRange)
        return returnMessage
    }
    
    class func createIgnoredUserMessage(msgObj:NSDictionary) -> NSAttributedString {
        let time = msgObj["time"] as NSString
        let username = msgObj["username"] as NSString
        let msg = msgObj["msg"] as NSString
        let message = NSString(format: "%@ %@: %@", time, username, msg)
        let returnMessage = NSMutableAttributedString(string: message)
        let messageRange = message.rangeOfString(msg)
        let messageFont = UIFont.boldSystemFontOfSize(12)
        let timeFont = UIFont(name: "Helvetica Neue", size: 10)
        let timeRange = message.rangeOfString(time)
        let usernameFont = UIFont.boldSystemFontOfSize(12)
        let usernameRange = message.rangeOfString(username + ":")
        
        returnMessage.addAttribute(kCTFontAttributeName, value: timeFont!, range: timeRange)
        returnMessage.addAttribute(kCTFontAttributeName, value: usernameFont, range: usernameRange)
        returnMessage.addAttribute(kCTFontAttributeName, value: messageFont, range: messageRange)
        return returnMessage

    }
}