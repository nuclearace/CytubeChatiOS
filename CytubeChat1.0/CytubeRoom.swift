//
//  CytubeRoom.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

class CytubeRoom: NSObject {
    
    weak var chatWindow:ChatWindowController?
    weak var roomsController:RoomsController?
    weak var userlistView:UserlistController?
    var active:Bool = false
    var closed:Bool = false
    var connected:Bool = false
    var loggedIn:Bool = false
    var kicked:Bool = false
    var messageBuffer:NSMutableArray = NSMutableArray()
    var needDelete:Bool = false
    var password:String!
    let roomName:String!
    var roomPassword:String!
    var sentRoomPassword:Bool = false
    let server:String!
    var shouldReconnect:Bool = true
    var socket:CytubeSocket?
    var userlist = [CytubeUser]()
    var username:String!
    
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
        roomsController?.tblRoom.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName("roomRemoved", object: nil)
    }
    
    func addHandlers() {
        NSLog("Adding Handlers for room: \(self.roomName)")
        self.socket?.on("connect") {[weak self] (data:AnyObject?) in
            NSLog("Connected to Cytube Room \(self?.roomName)")
            self?.connected = true
            self?.socket?.send("initChannelCallbacks", args: nil, singleArg: false)
            self?.socket?.send("joinChannel", args: ["name": self!.roomName], singleArg: false)
            self?.messageBuffer.removeAllObjects()
            self?.sendLogin()
        }
        
        self.socket?.on("disconnect") {[weak self] (data:AnyObject?) in
            self?.connected = false
            self?.socketShutdown()
            self?.messageBuffer.removeAllObjects()
            self?.chatWindow?.messageView.reloadData()
        }
        
        self.socket?.on("serverFailure") {[weak self] (data:AnyObject?) in
            NSLog("The server failed")
            self?.handleImminentDelete()
        }
        
        self.socket?.on("chatMsg") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            self?.handleChatMsg(data)
        }
        
        self.socket?.on("login") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            let success:Bool = data["success"] as Bool
            if (success) {
                self?.loggedIn = true
                self?.chatWindow?.chatInput.enabled = true
                self?.chatWindow?.loginButton.enabled = false
            } else {
                if let error = data["error"] as? NSString {
                    self?.loggedIn = false
                    self?.chatWindow?.chatInput.enabled = false
                    self?.chatWindow?.loginButton.enabled = true
                    CytubeUtils.displayGenericAlertWithNoButtons("Login Failed", message: error,
                        view: self?.chatWindow, completion: nil)
                }
            }
        }
        
        self.socket?.on("userlist") {[weak self] (data:AnyObject?) in
            let data = data as NSArray
            self?.handleUserlist(data)
            self?.sortUserlist()
        }
        
        self.socket?.on("addUser") {[weak self] (data:AnyObject?) in
            let data = data as NSDictionary
            self?.handleAddUser(data)
            self?.sortUserlist()
        }
        
        self.socket?.on("userLeave") {[weak self] (data:AnyObject?) in
            let data = (data as NSDictionary)["name"] as NSString
            self?.handleUserLeave(data)
        }
        
        self.socket?.on("kick") {[weak self] (data:AnyObject?) in
            var reason = (data as NSDictionary)["reason"] as NSString
            self?.kicked = true
            NSNotificationCenter.defaultCenter().postNotificationName("wasKicked", object: reason)
            self?.closeRoom()
        }
        
        self.socket?.on("needPassword") {[weak self] (data:AnyObject?) in
            if (self?.roomPassword != nil && self?.roomPassword != "") {
                self?.handleRoomPassword()
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("passwordFail", object: self)
                self?.handleImminentDelete()
            }
        }
        
        self.socket?.on("cancelNeedPassword") {[weak self] (data:AnyObject?) in
            if (self? != nil) {
                self?.sentRoomPassword = false
            }
        }
        
        self.socket?.on("clearchat") {[weak self] (data:AnyObject?) in
            if (self != nil) {
                self?.clearChat()
            }
        }
    }
    
    func handleAddUser(user:NSDictionary) {
        var tempUser = CytubeUser(user: user)
        if (!CytubeUtils.userlistContainsUser(self.userlist, user: tempUser)) {
            self.userlist.append(tempUser)
            self.sortUserlist()
            self.userlistView?.tblUserlist.reloadData()
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
        
        self.addMessageToChat(msg)
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
            self.socket?.send("channelPassword", args: self.roomPassword, singleArg: true)
            self.sentRoomPassword = true
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("passwordFail", object: self)
            self.handleImminentDelete()
        }
    }
    
    func handleUserLeave(username:String) {
        for var i = 0; i < self.userlist.count; ++i {
            var user = self.userlist[i] as CytubeUser
            if (user.getUsername() == username) {
                self.userlist.removeAtIndex(i)
                self.userlistView?.tblUserlist.reloadData()
            }
        }
    }
    
    func handleUserlist(userlist:NSArray) {
        self.userlist.removeAll(keepCapacity: false)
        for user in userlist {
            self.userlist.append(CytubeUser(user: user as NSDictionary))
        }
    }
    
    func addMessageToChat(msg:String) {
        if (self.messageBuffer.count > 100) {
            self.messageBuffer.removeObjectAtIndex(0)
        }
        self.messageBuffer.addObject(msg)
        self.chatWindow?.scrollChat()
    }
    
    func clearChat() {
        self.messageBuffer.removeAllObjects()
        self.chatWindow?.messageView.reloadData()
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
    
    func sortUserlist() {
        sort(&self.userlist) {$0 > $1}
    }
    
    func sendChatMsg(msg:String?) {
        if (!self.loggedIn || msg == nil) {
            return
        }
        
        let msgData = [
            "msg": msg!
        ]
        self.socket?.send("chatMsg", args: msgData, singleArg: false)
    }
    
    func sendLogin() {
        if (self.username != nil) {
            let loginData = [
                "name": self.username,
                "pw": self.password
            ]
            self.socket?.send("login", args: loginData, singleArg: false)
        }
    }
    
    func openSocket() {
        if (!self.connected) {
            self.kicked = false
            self.closed = false
            self.socket?.open()
        }
    }
    
    func closeSocket() {
        NSLog("Closing socket for \(self.roomName)")
        self.socket?.shutdownPingTimer()
        self.socket?.close()
        self.connected = false
        self.closed = true
        self.shouldReconnect = false
    }
    
    func socketShutdown() {
        println("SOCKET SHUTDOWN")
        if (self.needDelete) {
            var index = roomMng.findRoomIndex(self.roomName, server: self.socket!.server)
            roomMng.removeRoom(index!)
        } else if (self.closed && self.shouldReconnect) {
            self.socket?.reconnect()
        }
    }
    
    func closeRoom() {
        if (self.connected == false) {
            return
        }
        
        NSLog("Closing room \(self.roomName)")
        socket?.shutdownPingTimer()
        socket?.close()
        self.connected = false
        self.userlist.removeAll(keepCapacity: false)
        self.messageBuffer.removeAllObjects()
        self.username = nil
        self.password = nil
        self.chatWindow = nil
        self.userlistView = nil
        self.loggedIn = false
        self.active = false
        self.shouldReconnect = false
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
    
    func setView(roomsController:RoomsController) {
        self.roomsController = roomsController
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