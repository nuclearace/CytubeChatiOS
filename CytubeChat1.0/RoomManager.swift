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
        for cRoom in roomMng.rooms {
            if (cRoom.server == server && cRoom.room == room) {
                return cRoom.cytubeRoom
            }
        }
        return nil
    }
    
    func findRoomIndex(room:String, server:String) -> Int? {
        for var i = 0; i < roomMng.rooms.count; ++i {
            if (roomMng.rooms[i].server == server && roomMng.rooms[i].room == room) {
                return i
            }
        }
        return nil
    }
    
    func getActiveRoom() -> CytubeRoom? {
        for cRoom in roomMng.rooms {
            if (cRoom.cytubeRoom.active) {
                return cRoom.cytubeRoom
            }
        }
        return nil
    }
    
    func getRoomAtIndex(index:Int) -> CytubeRoom {
        return roomMng.rooms[index].cytubeRoom
    }
    
    func removeRoom(roomAtIndex: Int) -> CytubeRoom {
        println("Removing room at \(roomAtIndex)")
        var con = roomMng.rooms.removeAtIndex(roomAtIndex)
        return con.cytubeRoom
    }
}
