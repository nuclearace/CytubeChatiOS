//
//  RoomManager.swift
//  CytubeChat1.0
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
        println("Removing room at \(roomAtIndex)")
        var con = rooms.removeAtIndex(roomAtIndex)
        return con.cytubeRoom
    }
    
    func closeSockets() {
        for cRoom in rooms {
            cRoom.cytubeRoom?.closeSocket()
        }
    }
    
    func saveRooms() {
        NSLog("Saving Rooms")
        var handler = NSFileManager()
        var path:String?
        var pathsArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        path = pathsArray[0] as NSString + "/rooms"
        var roomsForSave:NSMutableArray = NSMutableArray()
        
        for room in rooms {
            var sroom = [
                "room": room.room,
                "server": room.server
            ]
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
        //var roomsFromData = handler.contentsAtPath(path!)
        if let roomsFromData:NSMutableArray? = NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as? NSMutableArray {
            for var i = 0; i < roomsFromData?.count; ++i {
                var con = roomsFromData?.objectAtIndex(i) as NSDictionary
                var recreatedRoom = CytubeRoom(roomName: con["room"] as NSString, server: con["server"] as NSString)
                self.addRoom(con["server"] as NSString, room: con["room"] as NSString, cytubeRoom: recreatedRoom)
            }
        }
        NSLog("Loaded Rooms")
        return true
    }
}
