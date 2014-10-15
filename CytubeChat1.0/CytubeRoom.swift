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
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
    }
    
    func addHandlers() {
        socket?.on("chatMsg") {(data:AnyObject?) in
           let data = data as NSDictionary
            println(data["username"]? as NSString)
        }
        
        socket?.on("rank") {(data:AnyObject?) in
            println(data)
        }
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
        self.addHandlers()
    }
    
    func getSocket() -> CytubeSocket? {
        return self.socket
    }
    
    func setView(view:FirstViewController) {
        self.view = view
    }
}