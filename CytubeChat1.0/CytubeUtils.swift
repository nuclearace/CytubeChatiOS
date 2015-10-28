//
//  CytubeUtils.swift
//  CytubeChat
//
//  Created by Erik Little on 10/15/14.
//

import UIKit

final class CytubeUtils {
    static let session = NSURLSession(configuration: .defaultSessionConfiguration())
    
    static func addSocket(room room:CytubeRoom) {
        
        func findSocketURL(callback:(() -> Void)?) {
            let url =  "http://" + room.server + "/socketconfig/\(room.roomName).json"
            let request = NSURLRequest(URL: NSURL(string: url)!)
            
            session.dataTaskWithRequest(request) {[weak room] data, res, err in
                if err != nil || data == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSLog("Socket url fail:" + err!.localizedDescription)
                        defaultCenter.postNotificationName("socketURLFail", object: nil)
                    }
                    return
                } else {
                    do {
                        let realJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        if let servers = realJSON["servers"] as? [AnyObject] {
                            for server in servers {
                                if let dict = server as? NSDictionary {
                                    if dict["secure"] as? Bool == true && dict["ipv6"] == nil {
                                        room?.socketIOURL = dict["url"] as! String
                                    } else if dict["ipv6"] == nil {
                                        room?.socketIOURL = dict["url"] as! String
                                    }
                                }
                            }
                        }
                        
                        callback?()
                    } catch {
                        findServerOldSchool(callback)
                    }
                }
                }.resume()
        }
        
        func findServerOldSchool(callback: (() -> Void)?) {
            let url =  "http://" + room.server + "/sioconfig"
            let request = NSURLRequest(URL: NSURL(string: url)!)
            
            session.dataTaskWithRequest(request) {[weak room] data, res, err in
                if err != nil || data == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSLog("Socket url fail:" + err!.localizedDescription)
                        defaultCenter.postNotificationName("socketURLFail", object: nil)
                    }
                    return
                } else {
                    var mutable = NSString(data: data!, encoding: NSUTF8StringEncoding) as! String
                    if mutable["var IO_URLS="].matches().count == 0 {
                        dispatch_async(dispatch_get_main_queue()) {
                            NSLog("Socket url fail")
                            defaultCenter.postNotificationName("socketURLFail", object: nil)
                        }
                        return
                    }
                    mutable = mutable["var IO_URLS="] ~= ""
                    mutable = mutable["'"] ~= "\""
                    mutable[";var IO_URL=(.*)"] ~= ""
                    let jsonString = mutable[",IO_URL=(.*)"] ~= ""
                    let data = (jsonString as String).dataUsingEncoding(NSUTF8StringEncoding)
                    
                    do {
                        let realJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        
                        if realJSON["ipv4-ssl"] as? String != "" {
                            room?.socketIOURL = realJSON["ipv4-ssl"] as! String
                        } else {
                            room?.socketIOURL = realJSON["ipv4-nossl"] as! String
                        }
                        
                        callback?()
                    } catch {
                        NSLog("Error getting socket config the old way")
                    }
                    
                }
                }.resume()
        }
        
        // Find the url, and then set up the socket
        findSocketURL {[weak room] in room?.setUpSocket()}
    }
    
    static func filterChatMsg(data:String) -> String {
        var mut = data
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
    
    static func encryptPassword(password:String, key:String) -> String? {
        do {
            let edata = try CytubeChatRNCryptor.encryptData(password.dataUsingEncoding(NSUTF8StringEncoding,
                allowLossyConversion: true), password: key)
            return edata.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
        } catch {
            return nil
        }
        
    }
    
    static func decryptPassword(edata:NSData, key:String) -> String? {
        do {
            let pdata = try RNDecryptor.decryptData(edata, withPassword: key)
            return NSString(data: pdata, encoding: NSUTF8StringEncoding) as? String
        } catch {
            return nil
        }
    }
    
    static func generateKey() -> String {
        var returnString = ""
        for _ in 0..<13 {
            let ran = arc4random_uniform(256)
            returnString += String(ran)
        }
        return returnString
    }
    
    static func displayGenericAlertWithNoButtons(title title:String, message:String, view:UIViewController?) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {action in
                return
            }
            alert.addAction(action)
            view?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    static func userlistContainsUser(userlist userlist:[CytubeUser], user:CytubeUser) -> Bool {
        for cuser in userlist {
            if cuser === user {
                return true
            }
        }
        return false
    }
    
    static func userIsIgnored(ignoreList ignoreList:[String], user:AnyObject) -> Bool {
        if ignoreList.count == 0 {
            return false
        }
        
        for cuser in ignoreList {
            if let userAsCytubeUser = user as? CytubeUser {
                if cuser == userAsCytubeUser.username {
                    return true
                }
            } else if let userAsString = user as? String {
                if cuser == userAsString {
                    return true
                }
            }
        }
        return false
    }
    
    static func formatMessage(msgObj msgObj:NSDictionary) -> NSAttributedString {
        let time = msgObj["time"] as! String
        let username = msgObj["username"] as! String
        let msg = msgObj["msg"] as! String
        let message = NSString(format: "%@ %@: %@", time, username, msg)
        let returnMessage = NSMutableAttributedString(string: message as String)
        let timeFont = UIFont(name: "Helvetica Neue", size: 10)
        let timeRange = message.rangeOfString(time)
        let usernameFont = UIFont.boldSystemFontOfSize(12)
        let usernameRange = message.rangeOfString(username + ":")
        
        returnMessage.addAttribute(String(kCTFontAttributeName), value: timeFont!, range: timeRange)
        returnMessage.addAttribute(String(kCTFontAttributeName), value: usernameFont, range: usernameRange)
        return returnMessage
    }
    
    static func createIgnoredUserMessage(msgObj msgObj:NSDictionary) -> NSAttributedString {
        let time = msgObj["time"] as! String
        let username = msgObj["username"] as! String
        let msg = msgObj["msg"] as! String
        let message = NSString(format: "%@ %@: %@", time, username, msg)
        let returnMessage = NSMutableAttributedString(string: message as String)
        let messageRange = message.rangeOfString(msg)
        let messageFont = UIFont.boldSystemFontOfSize(12)
        let timeFont = UIFont(name: "Helvetica Neue", size: 10)
        let timeRange = message.rangeOfString(time)
        let usernameFont = UIFont.boldSystemFontOfSize(12)
        let usernameRange = message.rangeOfString(username + ":")
        
        returnMessage.addAttribute(String(kCTFontAttributeName), value: timeFont!, range: timeRange)
        returnMessage.addAttribute(String(kCTFontAttributeName), value: usernameFont, range: usernameRange)
        returnMessage.addAttribute(String(kCTFontAttributeName), value: messageFont, range: messageRange)
        return returnMessage
        
    }
}