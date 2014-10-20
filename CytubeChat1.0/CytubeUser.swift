//
//  CytubeUser.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/16/14.
//

import Foundation

class CytubeUser: NSObject {
    let username:String!
    var rank:Int!
    
    init(user:NSDictionary) {
        self.username = user["name"] as NSString
        self.rank = user["rank"] as Int
    }
    
    deinit {
        println("CytubeUser \(self.username) is being deint")
    }
    
    func getUsername() -> String {
        return self.username
    }
    
    func getRank() -> Int {
        return self.rank
    }
}