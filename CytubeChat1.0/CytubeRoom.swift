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
    var needDelete:Bool = false
    
    init(roomName:String) {
        super.init()
        self.roomName = roomName
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
        view?.tblRoom.reloadData()
    }
    
    func addHandlers() {
        socket?.on("connect") {[weak self] (data:AnyObject?) in
            self!.socket?.send("initChannelCallbacks", args: nil)
            self!.socket?.send("joinChannel", args: ["name": self!.roomName])
        }
        
        socket?.on("disconnect") {[weak self] (data:AnyObject?) in
            self!.socketShutdown()
        }
        
        socket?.on("chatMsg") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            self!.handleChatMsg(data)
        }
        
        socket?.on("rank") {(data:AnyObject?) in
            
        }
    }
    
    func handleChatMsg(data:NSDictionary) {
        let username:String = data["username"] as NSString
        var msg:String = data["msg"] as NSString
        let time:Int = data["time"] as Int
        
        msg = CytubeUtils.filterChatMsg(msg)
        
        println("\n\n\(msg)")
    }
    
    func handleImminentDelete() {
        println("Imminent room deletion: Shut down socket")
        self.needDelete = true
        self.socket?.socketio?.close()
    }
    
    func socketShutdown() {
        println("SOCKET SHUTDOWN")
        if (self.needDelete) {
            var index = roomMng.findRoomIndex(self.roomName, server: self.socket!.server)
            var us = roomMng.removeRoom(index!)
        } else { // TODO handle when we lose connection
            
        }
    }
    
    func getRoomName() -> String {
        return self.roomName
    }
    
    func setSocket(socket:CytubeSocket) {
        self.socket = socket
        self.addHandlers()
    }
    
    func getSocket() -> CytubeSocket? {
        return self.socket
    }
    
    func setView(view:FirstViewController) {
        self.view = view
    }
}