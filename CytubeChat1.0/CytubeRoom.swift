//
//  CytubeRoom.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

class CytubeRoom: NSObject {
    var active:Bool = false
    weak var chatWindow:ChatWindowController?
    var closed:Bool = false
    var connected:Bool = false
    var loggedIn:Bool = false
    var messageBuffer:NSMutableArray = NSMutableArray()
    var needDelete:Bool = false
    var password:String!
    let roomName:String!
    var roomPassword:String!
    var sentRoomPassword:Bool = false
    let server:String!
    var shouldReconnect:Bool = true
    var socket:CytubeSocket?
    var userlist:NSMutableArray = NSMutableArray()
    weak var userlistView:UserlistController?
    var username:String!
    weak var view:RoomsController?
    
    init(roomName:String, server:String, password:String?) {
        super.init()
        self.roomName = roomName
        self.roomPassword = password
        self.server = server
        self.socket = CytubeSocket(server: server, room: roomName, cytubeRoom: self)
        self.addHandlers()
    }
    
    deinit {
        println("CytubeRoom \(self.roomName) is being deinit")
        view?.tblRoom.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName("roomRemoved", object: nil)
    }
    
    func addHandlers() {
        NSLog("Adding Handlers for room: \(self.roomName)")
        socket?.on("connect") {[weak self] (data:AnyObject?) in
            NSLog("Connected to Cytube Room \(self?.roomName)")
            self?.connected = true
            self?.socket?.send("initChannelCallbacks", args: nil)
            self?.socket?.send("joinChannel", args: ["name": self!.roomName])
            self?.messageBuffer.removeAllObjects()
            self?.sendLogin()
        }
        
        socket?.on("disconnect") {[weak self] (data:AnyObject?) in
            self?.connected = false
            self?.socketShutdown()
            self?.messageBuffer.removeAllObjects()
            self?.chatWindow?.messageView.reloadData()
        }
        
        socket?.on("serverFailure") {[weak self] (data:AnyObject?) in
            NSLog("The server failed")
            self?.handleImminentDelete()
        }
        
        socket?.on("chatMsg") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            self?.handleChatMsg(data)
        }
        
        socket?.on("login") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            let success:Bool = data["success"] as Bool
            if (success) {
                self?.loggedIn = true
                self?.chatWindow?.chatInput.enabled = true
                self?.chatWindow?.loginButton.enabled = false
            }
        }
        
        socket?.on("userlist") {[weak self] (data:AnyObject?) in
            let data = data as NSArray
            self?.handleUserlist(data)
        }
        
        socket?.on("addUser") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            self?.handleAddUser(data)
        }
        
        socket?.on("userLeave") {[weak self] (data:AnyObject?) in
            let data = (data as NSDictionary)["name"] as NSString
            self?.handleUserLeave(data)
        }
        
        socket?.on("kick") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            self?.shouldReconnect = true
        }
        
        socket?.on("needPassword") {[weak self] (data:AnyObject?) in
            if (self?.roomPassword != nil && self?.roomPassword != "") {
                self?.handleRoomPassword()
            } else {
                self?.chatWindow?.showRoomJoinFailed("No password given, or incorrect password" +
                    "was given. Try adding room again.")
                self?.handleImminentDelete()
            }
        }
        
        socket?.on("cancelNeedPassword") {[weak self] (data:AnyObject?) in
            if (self? != nil) {
                self?.sentRoomPassword = false
            }
        }
    }
    
    func handleAddUser(user:NSDictionary) {
        if (!self.userlist.containsObject(user)) {
            self.userlist.addObject(CytubeUser(user: user))
            self.userlistView?.tblUserlist.reloadData()
        }
    }
    
    func handleChatMsg(data:NSDictionary) {
        println("Got chat message")
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
        if (self.connected) {
            println("Imminent room deletion: Shut down socket")
            self.needDelete = true
            self.socket?.close()
        } else {
            var index = roomMng.findRoomIndex(self.roomName, server: self.socket!.server)
            roomMng.removeRoom(index!)
        }
    }
    
    func handleRoomPassword() {
        if (self.roomPassword != nil && !self.sentRoomPassword) {
            socket?.send("channelPassword", args: self.roomPassword)
            self.sentRoomPassword = true
        } else {
            self.chatWindow?.showRoomJoinFailed("No password given, or incorrect password was given. Try adding room again.")
            self.handleImminentDelete()
        }
    }
    
    func handleUserLeave(username:String) {
        for var i = 0; i < self.userlist.count; ++i {
            var user = self.userlist.objectAtIndex(i) as CytubeUser
            if (user.getUsername() == username) {
                self.userlist.removeObjectAtIndex(i)
                self.userlistView?.tblUserlist.reloadData()
            }
        }
    }
    
    func handleUserlist(userlist:NSArray) {
        self.userlist.removeAllObjects()
        for user in userlist {
            self.userlist.addObject(CytubeUser(user: user as NSDictionary))
        }
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
        socket?.shutdownPingTimer()
        socket?.close()
        self.connected = false
        self.closed = true
    }
    
    func closeRoom() {
        if (self.connected == false) {
            return
        }
        
        NSLog("Closing socket for \(self.roomName)")
        socket?.close()
        self.connected = false
        self.userlist.removeAllObjects()
        self.messageBuffer.removeAllObjects()
        self.username = nil
        self.password = nil
        self.chatWindow = nil
        self.userlistView = nil
        self.loggedIn = false
        self.active = false
        self.shouldReconnect = false
    }
    
    func openSocket() {
        socket?.open()
    }
    
    func socketShutdown() {
        println("SOCKET SHUTDOWN")
        if (self.needDelete) {
            var index = roomMng.findRoomIndex(self.roomName, server: self.socket!.server)
            roomMng.removeRoom(index!)
        } else if (!self.closed && self.shouldReconnect) {
            self.socket?.reconnect()
        }
    }
    
    func getRoomName() -> String {
        return self.roomName
    }
    
    func setRoomPassword(password:String) {
        self.roomPassword = password
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