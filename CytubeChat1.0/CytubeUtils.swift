//
//  CytubeUtils.swift
//  CytubeChat
//
//  Created by Erik Little on 10/15/14.
//

import UIKit

class CytubeUtils {
    
    class func addSocket(#room:CytubeRoom) {
        func findSocketURL(callback:(() -> Void)?) {
            var jsonError:NSError?
            var url =  "http://" + room.server + "/sioconfig"
            
            var request = NSURLRequest(URL: NSURL(string: url)!)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) {[weak room] res, data, err in
                if ((err) != nil) {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSLog("Socket url fail:" + err.localizedDescription)
                        NSNotificationCenter.defaultCenter().postNotificationName("socketURLFail", object: nil)
                    }
                    return
                } else {
                    var stringData = NSString(data: data, encoding: NSUTF8StringEncoding) as String
                    var mutable = RegexMutable(stringData)
                    if (mutable["var IO_URLS="].matches().count == 0) {
                        dispatch_async(dispatch_get_main_queue()) {
                            NSLog("Socket url fail")
                            NSNotificationCenter.defaultCenter().postNotificationName("socketURLFail", object: nil)
                        }
                        return
                    }
                    mutable = mutable["var IO_URLS="] ~= ""
                    mutable = mutable["'"] ~= "\""
                    mutable[";var IO_URL=(.*)"] ~= ""
                    var jsonString = mutable[",IO_URL=(.*)"] ~= ""
                    let data = (jsonString as String).dataUsingEncoding(NSUTF8StringEncoding)
                    var realJSON:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: &jsonError)
                    
                    if realJSON != nil {
                        if (realJSON!["ipv4-ssl"] != "") {
                            room?.socketIOURL = realJSON!["ipv4-ssl"] as String
                        } else {
                            room?.socketIOURL = realJSON!["ipv4-nossl"] as String
                        }
                        
                        if (callback != nil) {
                            callback!()
                        }
                    }
                }
            }
        }
        
        // Find the url, and then set up the socket
        findSocketURL {[weak room] in
            if (room != nil) {
                room!.setUpSocket()}
        }
    }
    
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
        
        return mut as String
    }
    
    class func encryptPassword(password:String, key:String) -> String {
        let edata = CytubeChatRNCryptor.encryptData(password.dataUsingEncoding(NSUTF8StringEncoding,
            allowLossyConversion: true), password: key, error: nil)
        
        return edata.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
    }
    
    class func decryptPassword(edata:NSData, key:String) -> String? {
        var err:NSError?
        let pdata = RNDecryptor.decryptData(edata, withPassword: key, error: &err)
        if (err != nil) {
            println(err?.localizedDescription)
            return nil
        }
        
        return NSString(data: pdata, encoding: NSUTF8StringEncoding)!
    }
    
    class func generateKey() -> String {
        var returnString = ""
        for i in 0..<13 {
            let ran = arc4random_uniform(256)
            returnString += String(ran)
        }
        return returnString
    }
    
    class func displayGenericAlertWithNoButtons(#title:String, message:String, view:UIViewController?) {
        dispatch_async(dispatch_get_main_queue()) {() in
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {action in
                return
            }
            alert.addAction(action)
            if (view == nil) {
                var view = UIApplication.sharedApplication().keyWindow?.rootViewController
            }
            view?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    class func userlistContainsUser(#userlist:[CytubeUser], user:CytubeUser) -> Bool {
        for cuser in userlist {
            if (cuser.isEqual(user)) {
                return true
            }
        }
        return false
    }
    
    class func userIsIgnored(#ignoreList:[String], user:AnyObject) -> Bool {
        if (ignoreList.count == 0) {
            return false
        }
        
        for cuser in ignoreList {
            if let userAsCytubeUser = user as? CytubeUser {
                if (cuser == userAsCytubeUser.getUsername()) {
                    return true
                }
            } else if let userAsString = user as? String {
                if (cuser == userAsString) {
                    return true
                }
            }
        }
        return false
    }
    
    class func formatMessage(#msgObj:NSDictionary) -> NSAttributedString {
        let time = msgObj["time"] as String
        let username = msgObj["username"] as String
        let msg = msgObj["msg"] as String
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
    
    class func createIgnoredUserMessage(#msgObj:NSDictionary) -> NSAttributedString {
        let time = msgObj["time"] as String
        let username = msgObj["username"] as String
        let msg = msgObj["msg"] as String
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