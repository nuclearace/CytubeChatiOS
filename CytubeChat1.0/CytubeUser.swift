//
//  CytubeUser.swift
//  CytubeChat
//
//  Created by Erik Little on 10/16/14.
//

import Foundation
import UIkit

class CytubeUser: NSObject, Comparable {
    let username:String!
    var rank:Int!
    var afk = false
    
    init(user:NSDictionary) {
        self.username = user["name"] as NSString
        self.rank = user["rank"] as Int
        self.afk = (user["meta"] as NSDictionary)["afk"] as Bool
    }
    
    override func copy() -> AnyObject {
        let userObj = [
            "name": self.username,
            "rank": self.rank,
            "meta": [
                "afk": self.afk
            ]
        ]
        
        return CytubeUser(user: userObj)
    }
    
    deinit {
        println("CytubeUser \(self.username) is being deint")
    }
    
    func getColorValue() -> UIColor? {
        if (rank == 0) {
            return UIColor(red: 0.6, green: 0.6, blue: 0.23, alpha: 1)
        }
        
        if (rank == 2) {
            return UIColor(red: 0.07, green: 0.75, blue: 0.30, alpha: 1)
        }
        
        if (rank == 3) {
            return UIColor(red: 0.94, green: 0.7, blue: 0.30, alpha: 1)
        }
        
        if (rank == 4) {
            return UIColor(red: 0.36, green: 0, blue: 0.38, alpha: 1)
        }
        
        if (rank >= 5 && rank < 255) {
            return UIColor(red: 0.90, green: 0, blue: 0.38, alpha: 1)
        }
        
        if (rank >= 255) {
            return UIColor(red: 0.98, green: 0, blue: 0.35, alpha: 1)
        }
        return nil
    }
    
    func createAttributedStringForUser() -> NSAttributedString {
        let range = NSMakeRange(0, countElements(self.username))
        let attString = NSMutableAttributedString(string: self.username, attributes: nil)
        if let color = self.getColorValue() {
            attString.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        }
        
        if (self.afk) {
            let font = UIFont.italicSystemFontOfSize(16)
            attString.addAttribute(kCTFontAttributeName, value: font, range: range)
        }
        
        return attString
    }
    
    func getUsername() -> String {
        return self.username
    }
    
    func getRank() -> Int {
        return self.rank
    }
    
    func getAFK() -> Bool {
        return self.afk
    }
    
    func setAFK(afk:Bool) {
        self.afk = afk
    }
    
    override func isEqual(object:AnyObject?) -> Bool {
        var user = object as CytubeUser
        if (object === self) {
            return true
        } else if (user.username != self.username) {
            return false
        }
        return true
    }
}