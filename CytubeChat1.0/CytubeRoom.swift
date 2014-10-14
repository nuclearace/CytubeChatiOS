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
    
    init(roomName:String, socket:CytubeSocket) {
        self.roomName = roomName
        self.socket = socket
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
    }
    
    func getRoomName() -> String {
        return self.roomName
    }
    
    func getSocket() -> CytubeSocket? {
        return self.socket
    }
    
    class func convertFromNilLiteral() -> Void {
        
    }
}