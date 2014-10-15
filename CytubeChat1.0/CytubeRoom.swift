//
//  CytubeRoom.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//  Copyright (c) 2014 Tracy Cage Industries. All rights reserved.
//

import Foundation

class CytubeRoom: NSObject {
    let roomName:String!
    let socket:CytubeSocket?
    var view:FirstViewController?
    
    init(roomName:String, socket:CytubeSocket) {
        self.roomName = roomName
        self.socket = socket
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
    }
    
    func handleImminentDelete(completion: (() -> Void)!) {
        completion()
        view?.tblRoom.reloadData()
    }
    
    func handleImminentDeleteShutdownSocket() {
        println("Closing socket: Imminent room shutdown")
        self.socket?.socketio?.close()
    }
    
    func getRoomName() -> String {
        return self.roomName
    }
    
    func getSocket() -> CytubeSocket? {
        return self.socket
    }
    
    func setView(view:FirstViewController) {
        self.view = view
    }
}