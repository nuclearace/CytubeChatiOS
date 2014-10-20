//
//  CytubeRoom.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

class CytubeRoom: NSObject {
    var active:Bool = false
    var chatWindow:ChatWindowController?
    var connected:Bool = false
    var loggedIn:Bool = false
    var messageBuffer:NSMutableArray = NSMutableArray()
    var needDelete:Bool = false
    var password:String!
    let roomName:String!
    let server:String!
    var socket:CytubeSocket?
    var userlist:NSMutableArray = NSMutableArray()
    var userlistView:UserlistController?
    var username:String!
    var view:RoomsController?
    
    init(roomName:String, server:String) {
        super.init()
        self.roomName = roomName
        self.server = server
        self.socket = CytubeSocket(server: server, room: roomName, cytubeRoom: self)
        self.addHandlers()
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
        view?.tblRoom.reloadData()
    }
    
    func addHandlers() {
        socket?.on("connect") {[weak self] (data:AnyObject?) in
            self!.connected = true
            self!.socket?.send("initChannelCallbacks", args: nil)
            self!.socket?.send("joinChannel", args: ["name": self!.roomName])
            self!.sendLogin()
        }
        
        socket?.on("disconnect") {[weak self] (data:AnyObject?) in
            self!.socketShutdown()
            self?.connected = false
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
        
        socket?.on("userlist") {[weak self] (data:AnyObject?) in
            let data = data as NSMutableArray
            
            self?.userlist = data
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
        
        msg =  "[" + dateFormatter.stringFromDate(date) + "] "
        msg += username + ": "
        msg += filterMsg
        
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
        self.socket?.close()
    }
    
    func isConnected() -> Bool {
        if ((socket?) != nil) {
            if (socket!.connected) {
                return true
            } else {
                return false
            }
        }
        return false
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
            socket?.send("login", args: [
                "name": self.username,
                "pw": self.password]
            )
        }
    }
    
    func closeSocket() {
        NSLog("Closing socket for \(self.roomName)")
        socket?.close()
    }
    
    
    func openSocket() {
        socket?.open()
    }
    
    func addNewSocket() {
        socket = CytubeSocket(server: self.server, room: self.roomName, cytubeRoom: self)
        self.addHandlers()
    }
    
    func socketShutdown() {
        println("SOCKET SHUTDOWN")
        if (self.needDelete) {
            var index = roomMng.findRoomIndex(self.roomName, server: self.socket!.server)
            roomMng.removeRoom(index!)
        } else {
            self.socket?.reconnect()
        }
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
    
    func setUserlistView(userlistView:UserlistController?) {
        self.userlistView = userlistView
    }
}