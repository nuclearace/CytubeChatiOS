//
//  CytubeUtils.swift
//  CytubeChat1.0
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
    
    class func displayGenericAlertWithNoButtons(title:String, message:String) {
        dispatch_async(dispatch_get_main_queue()) {() in
            var version = UIDevice.currentDevice().systemVersion["(.*)\\."][1]
            var versionInt:Int? = version.toInt()
            
            if (versionInt < 8) {
                var alert:UIAlertView = UIAlertView(title: title, message: message,
                    delegate: self, cancelButtonTitle: "Okay")
                alert.show()
            } else {
                var view = UIApplication.sharedApplication().keyWindow?.rootViewController
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                var action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) {(action:UIAlertAction?) in
                    return
                }
                alert.addAction(action)
                view?.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
}