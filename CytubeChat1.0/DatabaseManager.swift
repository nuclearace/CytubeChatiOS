//
//  DatabaseManager.swift
//  CytubeChat
//
//  Created by Erik Little on 12/12/14.
//

import Foundation
import SQLite

final class DatabaseManger {
    var db: Connection!
    
    init?() {
        var shouldCreateTables = true
        let manager = NSFileManager.defaultManager()
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask, true)
        
        let documentsDirectory = paths[0]
        let destPath = NSURL(string: documentsDirectory)!.URLByAppendingPathComponent("cytubechat.db")
        if manager.fileExistsAtPath(destPath.absoluteString) {
            shouldCreateTables = false
        }
        
        do {
            db = try Connection(destPath.absoluteString)
            try manager.setAttributes([NSFileProtectionKey: NSFileProtectionComplete],
                ofItemAtPath: destPath.absoluteString)
            
            if shouldCreateTables {
                createTables()
            }
        } catch {
            db = nil
            return nil
        }
    }
    
    func createTables() {
        let channels = Table("channels")
        let name = Expression<String>("name")
        let username = Expression<String>("username")
        let password = Expression<String>("password")
        let key = Expression<String>("key")
        do {
            try db.run(channels.create {t in
                t.column(name, unique: true)
                t.column(username)
                t.column(password)
                t.column(key)
                })
        } catch {
            NSLog("Error creating tables")
        }
    }
    
    func getUsernamePasswordForChannel(server server:String, channel:String) -> (String, String)? {
        let channels = Table("channels")
        let name = Expression<String>("name")
        let username = Expression<String>("username")
        let password = Expression<String>("password")
        let key = Expression<String>("key")
        let query = channels.select(username, password, key).filter(name == (server + "." + channel))
        
        for user in db.prepare(query) {
            let passwordData = NSData(base64EncodedString: user[password], options: NSDataBase64DecodingOptions())
            let upword = CytubeUtils.decryptPassword(passwordData!, key: user[key])
            if (upword != nil) {
                return (user[username], upword!)
            }
        }
        
        return nil
    }
    
    func insertEntryForChannel(server server:String, channel:String, uname:String, pword:String) {
        let channels = Table("channels")
        let name = Expression<String>("name")
        let username = Expression<String>("username")
        let password = Expression<String>("password")
        let key = Expression<String>("key")
        let completeChannel = server + "." + channel
        let key2 = CytubeUtils.generateKey()
        let ePassword = CytubeUtils.encryptPassword(pword, key: key2)
        let insert = channels.insert(name <- completeChannel, username <- uname, password <- ePassword!, key <- key2)
        
        do {
            try db.run(insert)
        } catch {
            do {
                try db.run(channels.filter(name == completeChannel)
                    .update(username <- uname, password <- ePassword!, key <- key2))
            } catch {
                
            }
        }
    }
    
    func removeEntryForChannel(server server:String, channel:String) {
        let channels = Table("channels")
        let name = Expression<String>("name")
        let channelToFind = server + "." + channel
        
        let foundChannel = channels.filter(name == channelToFind)
        do {
            try db.run(foundChannel.delete())
        } catch {
            
        }
    }
}
