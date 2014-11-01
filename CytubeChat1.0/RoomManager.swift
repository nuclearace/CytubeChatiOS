//
//  RoomManager.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

var roomMng:RoomManager = RoomManager()

struct RoomContainer {
    var server = "No Server"
    var room = "No Room"
    var cytubeRoom:CytubeRoom!
}

class RoomManager: NSObject {
    var rooms = [RoomContainer]()
    var roomsDidClose:Bool = false
    
    func addRoom(server:String, room:String, cytubeRoom:CytubeRoom) {
        rooms.append(RoomContainer(server: server, room: room, cytubeRoom: cytubeRoom))
    }
    
    func findRoom(room:String, server:String) -> CytubeRoom? {
        for cRoom in rooms {
            if (cRoom.server == server && cRoom.room == room) {
                return cRoom.cytubeRoom
            }
        }
        return nil
    }
    
    func findRoomIndex(room:String, server:String) -> Int? {
        for var i = 0; i < roomMng.rooms.count; ++i {
            if (rooms[i].server == server && rooms[i].room == room) {
                return i
            }
        }
        return nil
    }
    
    func getActiveRoom() -> CytubeRoom? {
        for cRoom in rooms {
            if (cRoom.cytubeRoom.active) {
                return cRoom.cytubeRoom
            }
        }
        return nil
    }
    
    func getRoomAtIndex(index:Int) -> CytubeRoom {
        return rooms[index].cytubeRoom
    }
    
    func removeRoom(roomAtIndex: Int) -> CytubeRoom {
        var con = rooms.removeAtIndex(roomAtIndex)
        self.saveRooms()
        return con.cytubeRoom
    }
    
    func closeRooms() {
        self.roomsDidClose = true
        for cRoom in rooms {
            if (cRoom.cytubeRoom? != nil && cRoom.cytubeRoom!.isConnected()) {
                cRoom.cytubeRoom?.closeSocket()
            }
        }
    }
    
    func reopenRooms() {
        if (!self.roomsDidClose) {
            return
        }
        self.roomsDidClose = false
        for cRoom in rooms {
            if (cRoom.cytubeRoom? != nil && cRoom.cytubeRoom!.closed) {
                cRoom.cytubeRoom?.openSocket()
            }
        }
    }
    
    func saveRooms() {
        NSLog("Saving Rooms")
        var handler = NSFileManager()
        var path:String?
        var pathsArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        path = pathsArray[0] as NSString + "/rooms"
        var roomsForSave:NSMutableArray = NSMutableArray()
        var sroom:NSDictionary!
        
        for room in rooms {
            if let roomPassword = room.cytubeRoom?.roomPassword? {
                sroom = [
                    "room": room.room,
                    "server": room.server,
                    "roomPassword": roomPassword
                ]
                
            } else {
                var sroom = [
                    "room": room.room,
                    "server": room.server,
                    "roomPassword": ""
                ]
            }
            roomsForSave.addObject(sroom)
        }
        
        var roomData = NSKeyedArchiver.archivedDataWithRootObject(roomsForSave)
        handler.createFileAtPath(path!, contents: roomData, attributes: nil)
        NSLog("Rooms saved")
    }
    
    func loadRooms() -> Bool {
        NSLog("Loading rooms")
        var handler = NSFileManager()
        var path:String?
        var pathsArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        path = pathsArray[0] as NSString + "/rooms"
        
        if (!handler.fileExistsAtPath(path!)) {
            return false
        }
        if let roomsFromData:NSMutableArray? = NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? NSMutableArray {
            for var i = 0; i < roomsFromData?.count; ++i {
                var con = roomsFromData?.objectAtIndex(i) as NSDictionary
                var recreatedRoom = CytubeRoom(roomName: con["room"] as NSString, server: con["server"] as NSString, password: con["roomPassword"] as NSString)
                self.addRoom(con["server"] as NSString, room: con["room"] as NSString, cytubeRoom: recreatedRoom)
            }
        }
        NSLog("Loaded Rooms")
        return true
    }
}
