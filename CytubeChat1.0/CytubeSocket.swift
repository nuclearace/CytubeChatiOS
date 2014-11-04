//
//  CytubeSocket.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

private struct socketFrame {
    var name:String!
    var args:AnyObject!
    
    init(name:String, args:AnyObject?) {
        self.name = name
        self.args = args?
    }
    
    func createFrameForSending() -> String {
        var array = "42["
        array += "\"" + name + "\""
        if (args? != nil) {
            if (args is NSDictionary) {
                array += ","
                var jsonSendError:NSError?
                var jsonSend = NSJSONSerialization.dataWithJSONObject(args, options: NSJSONWritingOptions(0), error: &jsonSendError)
                var jsonString = NSString(data: jsonSend!, encoding: NSUTF8StringEncoding)
                return array + jsonString! + "]"
            } else {
                array += "\"" + name + "\""
                array += ",\"\(args!)\""
                return array + "]"
            }
        } else {
            return array + "]"
        }
    }
}

class EventHandler: NSObject {
    let event:String!
    let callback:((data:AnyObject?) -> Void)!
    
    init(event:String, callback:((data:AnyObject?) -> Void)?) {
        self.event = event
        self.callback = callback
    }
    
    deinit {
        println("deint handler for \(event)")
    }
    
    func executeCallback(args:AnyObject?) {
        if (args != nil) {
            callback(data: args!)
        } else {
            callback(data: nil)
        }
    }
}

class CytubeSocket: NSObject, SRWebSocketDelegate {
    weak var cytubeRoom:CytubeRoom?
    let session:NSURLSession?
    let room:String!
    let server:String!
    let sioconfigURL = "/sioconfig"
    var socketio:SRWebSocket?
    var connecting = false
    var pingTimer:NSTimer!
    var isSSL = false
    var socketIOURL:String!
    var handlers = [EventHandler]()
    var connected = false
    
    init(server:String, room:String, cytubeRoom:CytubeRoom) {
        super.init()
        
        let sessionConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.allowsCellularAccess = true
        sessionConfig.HTTPAdditionalHeaders = ["Content-Type": "application/json"]
        sessionConfig.timeoutIntervalForRequest = 30
        sessionConfig.timeoutIntervalForResource = 60
        sessionConfig.HTTPMaximumConnectionsPerHost = 1
        
        self.session = NSURLSession(configuration: sessionConfig)
        self.server = server
        self.room = room
        self.cytubeRoom = cytubeRoom
        self.findSocketURL()
    }
    
    deinit {
        self.socketio = nil
        println("CytubeSocket for room \(self.room) is being deint")
    }
    
    //
    //
    // Setup WebSocket methods
    //
    // Finds the correct socket URL
    private func findSocketURL() {
        var jsonError:NSError?
        var url =  "http://" + self.server + self.sioconfigURL
        println("Finding socket URL: " + url)
        
        var request:NSURLRequest = NSURLRequest(URL: NSURL(string: url)!)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) {[weak self]
            (res, data, err) -> Void in
            if ((err) != nil) {
                dispatch_async(dispatch_get_main_queue()) {[weak self]() in
                    NSLog("Socket url fail:" + err.localizedDescription)
                    self?.findSocketURLFailed()
                }
                return
            } else {
                var stringData = NSString(data: data, encoding: NSUTF8StringEncoding) as String
                var mutable = RegexMutable(stringData)
                mutable = mutable["var IO_URLS="] ~= ""
                mutable = mutable["'"] ~= "\""
                mutable[";var IO_URL=(.*)"] ~= ""
                var jsonString = mutable[",IO_URL=(.*)"] ~= ""
                let data = (jsonString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                var realJSON:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: &jsonError)
                
                if realJSON != nil {
                    if (realJSON!["ipv4-ssl"] != "") {
                        self?.socketIOURL = RegexMutable((realJSON!["ipv4-ssl"] as NSString))["https://"] ~= ""
                        self?.isSSL = true
                    } else {
                        self?.socketIOURL = RegexMutable((realJSON!["ipv4-nossl"] as NSString))["http://"] ~= ""
                    }
                }
            }
        }
    }
    
    private func findSocketURLFailed() {
        CytubeUtils.displayGenericAlertWithNoButtons("Error", message:
            "Something is wrong with your server URL. Try again", view: nil, completion: nil)
        NSLog("Failed to find socket URL")
        self.handleEvent(["name": "serverFailure"])
    }
    
    // Init the socket
    private func initHandshake() {
        var endpoint:String!
        if (self.isSSL) {
            endpoint = "wss://\(self.socketIOURL)/socket.io/?EIO=2&transport=websocket"
        } else {
            endpoint = "ws://\(self.socketIOURL)/socket.io/?EIO=2&transport=websocket"
        }
        self.socketConnect(endpoint)
    }
    
    private func socketConnect(url:NSString) {
        socketio = SRWebSocket(URL: NSURL(string: url))
        socketio!.delegate = self
        socketio!.open()
    }
    //
    // End setup WebSocket
    //
    
    // Handles socket events
    func handleEvent(json:AnyObject?) {
        
        func doEvent(evt:String, args:AnyObject?) {
            for handler in self.handlers {
                if (handler.event == evt) {
                    if (args != nil) {
                        handler.executeCallback(args! as AnyObject)
                    } else {
                        handler.executeCallback(nil)
                    }
                }
            }
        }
        
        let event:NSString = json!["name"] as NSString
        println("GOT EVENT: \(event)")
        if (json?.count > 1) {
            doEvent(event, json!["args"])
        } else {
            doEvent(event, nil)
        }
    }
    
    // Adds handlers to the socket
    func on(name:String, callback:((data:AnyObject?) -> Void)?) {
        var handler = EventHandler(event: name, callback: callback)
        self.handlers.append(handler)
    }
    
    func close() {
        self.socketio?.close()
        self.socketio = nil
        self.connected = false
    }
    
    // Starts the connection to the server
    func open() {
        if (self.socketIOURL == nil) {
            CytubeUtils.displayGenericAlertWithNoButtons("Error", message: "Tried to open socket before socket.io URL was found." +
                "Or there is an error getting the URL.", view: nil, completion: nil)
            return
        } else if (self.connecting || self.connected) {
            return
        }
        self.connecting = true
        self.initHandshake()
    }
    
    func reconnect() {
        self.open()
    }
    
    // Sends a frame
    func send(name:String, args:AnyObject?) {
        if (!self.connected) {
            return
        }
        
        let frame = socketFrame(name: name, args: args)
        let str = frame.createFrameForSending()
        
        println("SENDING: " + str)
        self.socketio?.send(str)
    }
    
    func sendPing() {
        if (!self.connected) {
            return
        }
        println("SENT PING")
        self.socketio?.send("2")
    }
    
    func shutdownPingTimer() {
        self.pingTimer.invalidate()
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message:AnyObject?) {
        // All incoming messages (socket.on()) are received in this function. Parsed with JSON
        if (message as NSString == "3") {
            println("GOT PONG")
            return
        } else if (message as NSString == "40" || message as NSString == "41" || message!.characterAtIndex(0) == 48 || message == nil) {
            return println("Got Trash")
        }
        
        // NSLog("MESSAGE: %@", message! as NSString)
        
        var messageMut = RegexMutable((message as NSString).substringFromIndex(2))
        var ranges = messageMut[","].ranges()
        if (ranges.count != 0) {
            messageMut.replaceCharactersInRange(ranges[0], withString: ",\"args\":")
        }
        messageMut.replaceCharactersInRange(NSMakeRange(0, 1), withString: "{\"name\":")
        messageMut.replaceCharactersInRange(NSMakeRange(messageMut.length - 1, 1), withString: "}")
        let data:NSData = messageMut.dataUsingEncoding(NSUTF8StringEncoding)!
        var jsonError:NSError?
        var json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
        
        if (json != nil) {
            self.handleEvent(json?)
        }
    }
    
    // Called when the socket is first opened
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        self.pingTimer = NSTimer.scheduledTimerWithTimeInterval(25, target: self,
            selector: Selector("sendPing"), userInfo: nil, repeats: true)
        self.connecting = false
        self.connected = true
        self.handleEvent(["name": "connect"])
    }
    
    // Called when the socket is closed
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.connected = false
        self.pingTimer.invalidate()
        println("Closed socket because: \(reason)")
        self.handleEvent(["name": "disconnect"])
    }
    
    func setCytubeRoom(room:CytubeRoom) {
        self.cytubeRoom = room
    }
    
}

