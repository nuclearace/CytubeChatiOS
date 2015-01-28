//
//  CytubeRoom.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

final class CytubeRoom: NSObject {
    weak var chatWindow:ChatWindowController?
    weak var roomsController:RoomsController?
    weak var userlistView:UserlistController?
    let server:String!
    let roomName:String!
    var active = false
    var closed = false
    var connected = false
    var ignoreList = [String]()
    var kicked = false
    var loggedIn = false
    var messageBuffer = NSMutableArray()
    var needDelete = false
    var password:String!
    var roomPassword:String!
    var reconnecting = false
    var sentRoomPassword = false
    var shouldReconnect = true
    var socket:SocketIOClient?
    var socketIOURL:String!
    var userlist = [CytubeUser]()
    var username:String!
    
    init(roomName:String, server:String, password:String?) {
        super.init()
        self.roomName = roomName
        self.roomPassword = password
        self.server = server
    }
    
    deinit {
        // println("CytubeRoom \(self.roomName) is being deinit")
        roomsController?.tblRoom.reloadData()
        defaultCenter.postNotificationName("roomRemoved", object: nil)
    }
    
    func addHandlers() {
        // println("Adding Handlers for room: \(self.roomName)")
        
        self.socket?.on("connect") {[weak self] data in
            // println("Connected to Cytube server \(self?.server)")
            self?.connected = true
            self?.reconnecting = false
            self?.socket?.emit("initChannelCallbacks")
            self?.socket?.emit("joinChannel", args: ["name": self!.roomName])
            self?.messageBuffer.removeAllObjects()
            self?.sendLogin()
        }
        
        self.socket?.on("disconnect") {[weak self] data in
            if self == nil {
                return
            }
            
            if !self!.reconnecting {
                self?.connected = false
                self?.socketShutdown()
                self?.messageBuffer.removeAllObjects()
                self?.chatWindow?.messageView.reloadData()
            }
        }
        
        self.socket?.on("reconnect") {[weak self] data in
            self?.connected = false
            self?.reconnecting = true
            self?.messageBuffer.removeAllObjects()
            self?.chatWindow?.messageView.reloadData()
        }
        
        self.socket?.on("chatMsg") {[weak self] data in
            let data = data as NSDictionary
            self?.handleChatMsg(data)
        }
        
        self.socket?.on("login") {[weak self] data in
            let data = data as NSDictionary
            let success = data["success"] as Bool
            if success {
                self?.loggedIn = true
                self?.chatWindow?.chatInput.enabled = true
                self?.chatWindow?.loginButton.enabled = false
            } else {
                if let error = data["error"] as? String {
                    self?.loggedIn = false
                    self?.forgetUser()
                    self?.chatWindow?.chatInput.enabled = false
                    self?.chatWindow?.loginButton.enabled = true
                    CytubeUtils.displayGenericAlertWithNoButtons(title: "Login Failed", message: error,
                        view: self?.chatWindow)
                }
            }
        }
        
        self.socket?.on("userlist") {[weak self] data in
            let data = data as NSArray
            self?.handleUserlist(data)
            self?.sortUserlist()
            self?.userlistView?.tblUserlist.reloadData()
        }
        
        self.socket?.on("addUser") {[weak self] data in
            let data = data as NSDictionary
            self?.handleAddUser(data)
        }
        
        self.socket?.on("userLeave") {[weak self] data in
            let data = (data as NSDictionary)["name"] as String
            self?.handleUserLeave(data)
        }
        
        self.socket?.on("setAFK") {[weak self] data in
            let username = (data as NSDictionary)["name"] as String
            let afk = (data as NSDictionary)["afk"] as Bool
            self?.handleSetAFK(username, afk: afk)
        }
        
        self.socket?.on("kick") {[weak self] data in
            let reason = (data as NSDictionary)["reason"] as String
            let kickObj = [
                "reason": reason,
                "room": self!.roomName
            ]
            self?.kicked = true
            self?.shouldReconnect = false
            defaultCenter.postNotificationName("wasKicked", object: kickObj)
        }
        
        self.socket?.on("needPassword") {[weak self] data in
            if self?.roomPassword != nil && self?.roomPassword != "" {
                self?.handleRoomPassword()
            } else {
                defaultCenter.postNotificationName("passwordFail", object: self)
                self?.handleImminentDelete()
            }
        }
        
        self.socket?.on("cancelNeedPassword") {[weak self] data in
            self?.sentRoomPassword = false
            return
        }
        
        self.socket?.on("clearchat") {[weak self] data in
            self?.clearChat()
            return
        }
    }
    
    func handleAddUser(user:NSDictionary) {
        let tempUser = CytubeUser(user: user)
        if !CytubeUtils.userlistContainsUser(userlist: self.userlist, user: tempUser) {
            self.userlist.append(tempUser)
            self.sortUserlist()
            self.userlistView?.tblUserlist.reloadData()
        }
    }
    
    func handleChatMsg(data:NSDictionary) {
        let username = data["username"] as String
        let msg = data["msg"] as String
        let time = data["time"] as NSTimeInterval / 1000
        let dateFormatter = NSDateFormatter()
        let date = NSDate(timeIntervalSince1970: time)
        dateFormatter.dateFormat = "HH:mm:ss z"
        
        if CytubeUtils.userIsIgnored(ignoreList: self.ignoreList, user: username) {
            let msgObj = [
                "time": "[" + dateFormatter.stringFromDate(date) + "]",
                "username": username,
                "msg": "User Ignored"
            ]
            return self.addMessageToChat(
                CytubeUtils.createIgnoredUserMessage(msgObj: msgObj))
        }
        
        let msgObj = [
            "time": "[" + dateFormatter.stringFromDate(date) + "]",
            "username": username,
            "msg": CytubeUtils.filterChatMsg(msg)
        ]
        
        self.addMessageToChat(CytubeUtils.formatMessage(msgObj: msgObj))
    }
    
    func handleImminentDelete() {
        if self.connected {
            // println("Imminent room deletion: Shut down socket")
            self.needDelete = true
            self.socket?.close()
        } else {
            let index = roomMng.findRoomIndex(self.roomName, server: self.server)
            roomMng.removeRoom(index!)
        }
    }
    
    func handleRoomPassword() {
        if self.roomPassword != nil && !self.sentRoomPassword {
            self.socket?.emit("channelPassword", args: self.roomPassword)
            self.sentRoomPassword = true
        } else {
            defaultCenter.postNotificationName("passwordFail", object: self)
            self.handleImminentDelete()
        }
    }
    
    func handleSetAFK(username:String, afk:Bool) {
        for user in self.userlist {
            if user.username == username {
                user.afk = afk
                self.userlistView?.tblUserlist.reloadData()
            }
        }
    }
    
    func handleUserLeave(username:String) {
        self.userlist = self.userlist.filter {!($0.username == username)}
        self.userlistView?.tblUserlist.reloadData()
    }
    
    func handleUserlist(userlist:NSArray) {
        self.userlist.removeAll(keepCapacity: false)
        for user in userlist {
            self.userlist.append(CytubeUser(user: user as NSDictionary))
        }
    }
    
    func addMessageToChat(msg:NSAttributedString) {
        if self.messageBuffer.count > 75 {
            self.messageBuffer.removeObjectAtIndex(0)
        }
        
        self.messageBuffer.addObject(msg)
        self.chatWindow?.messageView.reloadData()
        self.chatWindow?.scrollChat()
    }
    
    func clearChat() {
        self.messageBuffer.removeAllObjects()
        self.chatWindow?.messageView.reloadData()
    }
    
    func isConnected() -> Bool {
        if self.socket == nil {
            return false
        }
        
        if socket!.connected {
            return true
        } else {
            return false
        }
    }
    
    func saveUser() {
        if self.username == nil {
            return
        }
        
        dbManger.insertEntryForChannel(server: self.server, channel: self.roomName,
            uname: self.username, pword: self.password!)
    }
    
    func forgetUser() {
        dbManger.removeEntryForChannel(server: self.server, channel: self.roomName)
    }
    
    func sendChatMsg(msg:String?) {
        if !self.loggedIn || msg == nil {
            return
        }
        
        let msgData = [
            "msg": msg!
        ]
        self.socket?.emit("chatMsg", args: msgData)
    }
    
    func sendLogin() {
        if self.username != nil {
            let loginData = [
                "name": self.username,
                "pw": self.password
            ]
            self.socket?.emit("login", args: loginData)
        }
    }
    
    func setUpSocket() {
        self.socket = SocketIOClient(socketURL: self.socketIOURL, opts: [
            "reconnects": false
            ])
        self.addHandlers()
    }
    
    func sortUserlist() {
        sort(&self.userlist) {$0 > $1}
    }
    
    func openSocket() {
        if !self.connected && self.socket != nil {
            self.kicked = false
            self.closed = false
            self.shouldReconnect = true
            self.socket?.open()
        } else if self.socket == nil {
            // Try and add the socket
            self.setUpSocket()
            self.kicked = false
            self.closed = false
            self.shouldReconnect = true
            self.socket?.open()
        }
    }
    
    func closeSocket() {
        // NSLog("Closing socket for \(self.roomName)")
        self.socket?.close()
        self.connected = false
        self.closed = true
        self.shouldReconnect = false
        self.userlist.removeAll(keepCapacity: false)
        self.userlistView?.tblUserlist.reloadData()
        self.messageBuffer.removeAllObjects()
        self.chatWindow?.messageView.reloadData()
    }
    
    func socketShutdown() {
        // println("SOCKET SHUTDOWN")
        if self.needDelete {
            var index = roomMng.findRoomIndex(self.roomName, server: self.server)
            roomMng.removeRoom(index!)
        } else if self.closed && self.shouldReconnect {
            self.socket?.open()
        }
    }
    
    func closeRoom() {
        if !self.connected {
            return
        }
        
        // NSLog("Closing room \(self.roomName)")
        self.socket?.close()
        self.connected = false
        self.userlist.removeAll(keepCapacity: false)
        self.messageBuffer.removeAllObjects()
        self.username = nil
        self.password = nil
        self.kicked = false
        self.chatWindow = nil
        self.userlistView = nil
        self.loggedIn = false
        self.active = false
        self.shouldReconnect = false
    }
    
    func setUserListView(view:UserlistController?) {
        self.userlistView = view
    }
    
    func setChatWindow(view:ChatWindowController?) {
        self.chatWindow = view
    }
}