//
//  CytubeUser.swift
//  CytubeChat
//
//  Created by Erik Little on 10/16/14.
//

import UIKit

class CytubeUser: Comparable {
    let username:String!
    var afk = false
    var profileImage:NSURL?
    var profileText:String?
    var rank:Int!
    
    init(user:NSDictionary) {
        self.username = user["name"] as String
        self.rank = user["rank"] as Int
        self.afk = (user["meta"] as NSDictionary)["afk"] as Bool
        if let imageString = (user["profile"] as NSDictionary)["image"] as? String {
            if imageString == "" {} else {
                self.profileImage = NSURL(string: imageString)
            }
        }
        self.profileText = (user["profile"] as NSDictionary)["text"] as? String
    }
    
    deinit {
        // println("CytubeUser \(self.username) is being deint")
    }
    
    func getColorValue() -> UIColor? {
        if rank == 0 {
            return UIColor(red: 0.6, green: 0.6, blue: 0.23, alpha: 1)
        }
        
        if rank == 2 {
            return UIColor(red: 0.07, green: 0.75, blue: 0.30, alpha: 1)
        }
        
        if rank == 3 {
            return UIColor(red: 0.94, green: 0.7, blue: 0.30, alpha: 1)
        }
        
        if rank == 4 {
            return UIColor(red: 0.36, green: 0, blue: 0.38, alpha: 1)
        }
        
        if rank >= 5 && rank < 255 {
            return UIColor(red: 0.90, green: 0, blue: 0.38, alpha: 1)
        }
        
        if rank >= 255 {
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
        
        if self.afk {
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
}