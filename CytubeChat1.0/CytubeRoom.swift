//
//  CytubeRoom.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

class CytubeRoom: NSObject {
    let roomName:String!
    var socket:CytubeSocket?
    var view:FirstViewController?
    
    init(roomName:String) {
        super.init()
        self.roomName = roomName
        self.addHandlers()
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
    }
    
    func addHandlers() {
        
    }
    
    func handleEvent(json:AnyObject?) {
        
        let event: NSString = json!["name"] as NSString
        
        if (event.isEqualToString("rank")) {
            //didReceiveFirstRank()
            return
        } else if (event.isEqualToString("emoteList")) {
            return
        } else if (event.isEqualToString("setPermissions")) {
            return
        } else if (event.isEqualToString("userlist")) {
            return
        } else if (event.isEqualToString("setPlaylistLocked")) {
            return
        } else if (event.isEqualToString("drinkCount")) {
            return
        } else if (event.isEqualToString("playlist")) {
            return
        } else if (event.isEqualToString("setCurrent")) {
            return
        } else if (event.isEqualToString("usercount")) {
            return
        }
        
        //let args:NSDictionary = (json?["args"] as NSArray)[0] as NSDictionary

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
    
    func setSocket(socket:CytubeSocket) {
        self.socket = socket
    }
    
    func getSocket() -> CytubeSocket? {
        return self.socket
    }
    
    func setView(view:FirstViewController) {
        self.view = view
    }
}