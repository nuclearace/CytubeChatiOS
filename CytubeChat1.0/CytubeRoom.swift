//
//  CytubeRoom.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

class CytubeRoom: NSObject {
    var active:Bool = false
    var loggedIn:Bool = false
    let roomName:String!
    var socket:CytubeSocket?
    var view:RoomsController?
    var chatWindow:ChatWindowController?
    var needDelete:Bool = false
    var messageBuffer:NSMutableArray = NSMutableArray()
    var username:String!
    var password:String!
    
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
        
        socket?.on("login") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            let success:Bool = data["success"] as Bool
            if (success) {
                self!.loggedIn = true
                self!.chatWindow?.chatInput.enabled = true
            }
        }
        
        socket?.on("rank") {[weak self] (data:AnyObject?) in
            
        }
    }
    
    func handleChatMsg(data:NSDictionary) {
        let username:String = data["username"] as NSString
        var msg:String = data["msg"] as NSString
        let time:NSTimeInterval = data["time"] as NSTimeInterval / 1000
        
        var dateFormatter:NSDateFormatter = NSDateFormatter()
        var date:NSDate = NSDate(timeIntervalSince1970: time)
        dateFormatter.dateFormat = "HH:mm:ss z"
        
        var filterMsg = CytubeUtils.filterChatMsg(msg)
        
        msg =  "[" + dateFormatter.stringFromDate(date) + "]"
        msg += username + ": "
        msg += filterMsg
        //println("\n\n\(msg)\n")
        
        if (messageBuffer.count > 100) {
            messageBuffer.removeObjectAtIndex(0)
            messageBuffer.addObject(msg)
        } else {
            messageBuffer.addObject(msg)
        }
        
        chatWindow?.scrollChat(messageBuffer.count)
    }
    
    func handleImminentDelete() {
        println("Imminent room deletion: Shut down socket")
        self.needDelete = true
        self.socket?.socketio?.close()
    }
    
    func sendChatMsg(msg:String?) {
        if (!self.loggedIn || msg == nil) {
            return
        }
        
        let msgData = [
            "msg": msg!
        ]
        
        socket?.send("chatMsg", args: msgData)
    }
    
    func sendLogin() {
        if (self.username != nil) {
            socket?.send("login", args:
                ["name": self.username,
                    "pw": self.password]
            )
        }
    }
    
    func socketShutdown() {
        println("SOCKET SHUTDOWN")
        if (self.needDelete) {
            var index = roomMng.findRoomIndex(self.roomName, server: self.socket!.server)
            roomMng.removeRoom(index!)
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
    
    func setActive(active:Bool) {
        self.active = active
    }
    
    func setView(view:RoomsController) {
        self.view = view
    }
    
    func setChatWindow(chatWindow:ChatWindowController?) {
        self.chatWindow = chatWindow
    }
    
    func setPassword(password:String) {
        self.password = password
    }
    
    func setUsername(username:String) {
        self.username = username
    }
}