//
//  RoomManager.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//  Copyright (c) 2014 Tracy Cage Industries. All rights reserved.
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
            } else {
                return nil
            }
        }
        return nil
    }
    
    func findRoomIndex(room:String, server:String) -> Int? {
        for var i = 0; i < roomMng.rooms.count; ++i {
            if let room = roomMng.findRoom(room, server: server) {
                return i
            }
        }
        return nil
    }
    
    func getRoomAtIndex(index:Int) -> CytubeRoom {
        return roomMng.rooms[index].cytubeRoom
    }
    
    func removeRoom(roomAtIndex: Int) {
        roomMng.rooms.removeAtIndex(roomAtIndex)
    }
}
