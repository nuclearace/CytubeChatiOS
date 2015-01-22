//
//  RoomManager.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

struct RoomContainer {
    var server = "No Server"
    var room = "No Room"
    var cytubeRoom:CytubeRoom!
}

final class RoomManager {
    var rooms = [RoomContainer]()
    var roomsDidClose = false
    
    init() {
        // Look for changes in network
        defaultCenter.addObserver(self, selector: "handleNetworkChange:",
            name: kReachabilityChangedNotification, object: nil)
    }
    
    deinit {
        defaultCenter.removeObserver(self)
    }
    
    func addRoom(server:String, room:String, cytubeRoom:CytubeRoom) {
        rooms.append(RoomContainer(server: server, room: room, cytubeRoom: cytubeRoom))
    }
    
    func findRoom(room:String, server:String) -> CytubeRoom? {
        for cRoom in rooms {
            if cRoom.server == server && cRoom.room == room {
                return cRoom.cytubeRoom
            }
        }
        return nil
    }
    
    func findRoomIndex(room:String, server:String) -> Int? {
        for i in 0..<roomMng.rooms.count {
            if rooms[i].server == server && rooms[i].room == room {
                return i
            }
        }
        return nil
    }
    
    func getActiveRoom() -> CytubeRoom? {
        for cRoom in rooms {
            if cRoom.cytubeRoom.active {
                return cRoom.cytubeRoom
            }
        }
        return nil
    }
    
    func getRoomAtIndex(index:Int) -> CytubeRoom {
        return rooms[index].cytubeRoom
    }
    
    func removeRoom(roomAtIndex:Int) -> CytubeRoom {
        let con = rooms.removeAtIndex(roomAtIndex)
        con.cytubeRoom.forgetUser()
        self.saveRooms()
        return con.cytubeRoom
    }
    
    func closeRooms() {
        self.roomsDidClose = true
        for cRoom in rooms {
            if cRoom.cytubeRoom? != nil && cRoom.cytubeRoom!.isConnected() {
                cRoom.cytubeRoom?.closeSocket()
            }
        }
    }
    
    func reopenRooms() {
        if !self.roomsDidClose {
            return
        }
        
        self.roomsDidClose = false
        for cRoom in rooms {
            if cRoom.cytubeRoom? != nil && cRoom.cytubeRoom!.closed {
                cRoom.cytubeRoom?.openSocket()
            }
        }
    }
    
    // If we go from wifi to cellular we need to reconnect
    @objc func handleNetworkChange(not:NSNotification) {
        let status = internetReachability.currentReachabilityStatus()
        if status.value == 2 {
            for cRoom in rooms {
                if (cRoom.cytubeRoom? != nil && cRoom.cytubeRoom!.connected) {
                    cRoom.cytubeRoom?.socket?.open()
                }
            }
        } else if status.value == 0 {
            for cRoom in rooms {
                if cRoom.cytubeRoom? != nil && cRoom.cytubeRoom!.connected {
                    cRoom.cytubeRoom?.closeSocket()
                }
            }
            defaultCenter.postNotificationName("noInternet", object: nil)
        }
    }
    
    func saveRooms() {
        NSLog("Saving Rooms")
        let handler = NSFileManager()
        var pointerErr:NSError?
        let pathsArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory,
            NSSearchPathDomainMask.UserDomainMask, true)
        let path = pathsArray[0] as NSString + "/rooms.json"
        var roomArray = [NSDictionary]()
        var sroom:NSDictionary!
        
        for room in rooms {
            if let roomPassword = room.cytubeRoom?.roomPassword? {
                sroom = [
                    "room": room.room,
                    "server": room.server,
                    "roomPassword": roomPassword
                ]
                
            } else {
                sroom = [
                    "room": room.room,
                    "server": room.server,
                    "roomPassword": ""
                ]
            }
            roomArray.append(sroom)
        }
        
        let roomsForSave = [
            "version": 1.0,
            "rooms": roomArray
        ]
        
        let jsonForWriting = NSJSONSerialization.dataWithJSONObject(roomsForSave,
            options: NSJSONWritingOptions.PrettyPrinted, error: &pointerErr)
        
        handler.createFileAtPath(path, contents: jsonForWriting, attributes: nil)
        NSLog("Rooms saved")
    }
    
    func loadRooms() -> Bool {
        NSLog("Loading rooms")
        let handler = NSFileManager()
        var pointerErr:NSError?
        let pathsArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory,
            NSSearchPathDomainMask.UserDomainMask, true)
        let path = pathsArray[0] as String + "/rooms.json"
        
        if !handler.fileExistsAtPath(path) {
            return false
        }
        
        let data = NSData(contentsOfFile: path)
        if let roomsFromData:NSDictionary = NSJSONSerialization.JSONObjectWithData(data!,
            options: NSJSONReadingOptions.AllowFragments, error: &pointerErr) as? NSDictionary  {
                for i in 0..<(roomsFromData["rooms"] as NSArray).count {
                    let con = (roomsFromData["rooms"] as NSArray)[i] as NSDictionary
                    let recreatedRoom = CytubeRoom(roomName: con["room"] as String,
                        server: con["server"] as String, password: con["roomPassword"] as? String)
                    CytubeUtils.addSocket(room: recreatedRoom)
                    self.addRoom(con["server"] as String, room: con["room"] as String, cytubeRoom: recreatedRoom)
                }
        }
        NSLog("Loaded Rooms")
        return true
    }
}
