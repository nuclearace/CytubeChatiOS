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
    
    func removeRoom(roomAtIndex: Int) {
        roomMng.rooms.removeAtIndex(roomAtIndex)
    }
}
