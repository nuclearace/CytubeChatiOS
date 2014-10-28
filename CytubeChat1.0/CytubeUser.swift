//
//  CytubeUser.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/16/14.
//

import Foundation
import UIkit

func ==(lhs:CytubeUser, rhs:CytubeUser) -> Bool {
    if lhs.rank == rhs.rank {
        return true
    }
    return false
}
func <(lhs:CytubeUser, rhs:CytubeUser) -> Bool {
    if lhs.rank < rhs.rank {
        return true
    }
    return false
}

class CytubeUser: NSObject, Comparable {
    let username:String!
    var rank:Int!
    
    init(user:NSDictionary) {
        self.username = user["name"] as NSString
        self.rank = user["rank"] as Int
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
    
    func getUsername() -> String {
        return self.username
    }
    
    func getRank() -> Int {
        return self.rank
    }
    
    override func isEqual(object:AnyObject?) -> Bool {
        if (object === self) {
            return true
        } else if ((object as NSDictionary)["name"] as NSString != self.username) {
            return false
        }
        return true
    }
}