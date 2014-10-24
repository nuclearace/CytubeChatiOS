//
//  CytubeSocket.swift
//  CytubeChat1.0
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
        var array = "["
        array += "\"" + name + "\""
        if (args? != nil) {
            array += ","
            var jsonSendError:NSError?
            var jsonSend = NSJSONSerialization.dataWithJSONObject(args, options: NSJSONWritingOptions(0), error: &jsonSendError)
            var jsonString = NSString(data: jsonSend!, encoding: NSUTF8StringEncoding)
            return array + jsonString + "]"
        } else {
            return array + "]"
        }
    }
    
    //    func toDict() -> NSDictionary {
    //        if (self.args != nil) {
    //            return [
    //                "name": name,
    //                "args": args
    //            ]
    //        } else {
    //            return [
    //                "name": self.name
    //            ]
    //        }
    //    }
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
    var socketio:SRWebSocket?
    var connecting:Bool = false
    var socketIOURL:String!
    let session:NSURLSession?
    let room:String!
    let server:String!
    let sioconfigURL:String = "/sioconfig"
    weak var cytubeRoom:CytubeRoom?
    var handlers:NSMutableArray = NSMutableArray()
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
        
        var request:NSURLRequest = NSURLRequest(URL: NSURL(string: url))
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) {[unowned self]
            (res, data, err) -> Void in
            if ((err) != nil) {
                NSLog(err.localizedDescription)
                return self.findSocketURLFailed()
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
                    self.socketIOURL = RegexMutable((realJSON!["ipv4-nossl"] as NSString))["http://"] ~= ""
                }
            }
        }
    }
    
    private func findSocketURLFailed() {
        CytubeUtils.displayGenericAlertWithNoButtons("Error", message: "Something is wrong with your server URL. Try again")
        var index = roomMng.findRoomIndex(self.room, server: self.server)
        roomMng.removeRoom(index!)
    }
    
    // Init the socket
    private func initHandshake() {
        println("init handshake")
        let time:NSTimeInterval = NSDate().timeIntervalSince1970 * 1000
        
        println(self.socketIOURL)
        var endpoint = "ws://\(self.socketIOURL)/socket.io/?EIO=2&transport=websocket"
        self.socketConnect(endpoint)
        
        //        var handshakeTask:NSURLSessionTask = session!.dataTaskWithURL(NSURL.URLWithString(endpoint), completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) in
        //            if (error == nil) {
        //                let stringData:NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
        //                let handshakeToken:NSString = stringData.componentsSeparatedByString(":")[0] as NSString
        //                println(stringData)
        //                println("HANDSHAKE \(handshakeToken)")
        //
        //                self.socketConnect(handshakeToken)
        //            } else {
        //                NSLog(error.localizedDescription)
        //                self.connecting = false
        //                self.cytubeRoom?.handleImminentDelete() {() in
        //                    CytubeUtils.displayGenericAlertWithNoButtons("Error", message: "Something is wrong with your server URL. Try again")
        //                }
        //            }
        //        })
        //        handshakeTask.resume()
    }
    
    private func socketConnect(token:NSString) {
        //socketio = SRWebSocket(URLRequest: NSURLRequest(URL: NSURL(string: "ws://\(self.socketIOURL)/socket.io/1/websocket/\(token)")))
        socketio = SRWebSocket(URL: NSURL(string: token))
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
        self.handlers.addObject(handler)
    }
    
    func close() {
        self.socketio?.close()
        self.socketio = nil
        self.connected = false
    }
    
    // Starts the connection to the server
    func open() {
        if (self.connecting) {
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
        
        var frame:socketFrame = socketFrame(name: name, args: args)
        
        //        var jsonSendError:NSError?
        //        var jsonSend = NSJSONSerialization.dataWithJSONObject(frame.toDict(), options: NSJSONWritingOptions(0), error: &jsonSendError)
        //        var jsonString1 = NSString(data: jsonSend!, encoding: NSUTF8StringEncoding)
        //        println("JSON SENT \(jsonString1)")
        let str:NSString = "42\(frame.createFrameForSending())"
        
        println("SENDING:" + str)
        socketio?.send(str)
    }
    
    func sendPong() {
        println("SENT PONG")
        self.socketio?.send("3")
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        // All incoming messages (socket.on()) are received in this function. Parsed with JSON
        //println("MESSAGE: \(message)")
        
        if (message as NSString == "2") {
            return self.sendPong()
        } else if (message as NSString == "40" || (message as NSString).characterAtIndex(0) == 0) {
            return
        }
        
        var jsonError:NSError?
        var messageMut = RegexMutable((message as NSString).substringFromIndex(2))
        
        var ranges = messageMut[","].ranges()
        if (ranges.count != 0) {
            messageMut.replaceCharactersInRange(ranges[0], withString: ",\"args\":")
        }
        messageMut.replaceCharactersInRange(NSMakeRange(0, 1), withString: "{\"name\":")
        messageMut.replaceCharactersInRange(NSMakeRange(messageMut.length - 1, 1), withString: "}")
        let data:NSData = messageMut.dataUsingEncoding(NSUTF8StringEncoding)!
        var json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
        
        if json != nil {
            self.handleEvent(json?)
        }
    }
    
    // Called when the socket was closed
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.connected = false
        println("Closed socket because: \(reason)")
        self.handleEvent(["name": "disconnect"])
    }
    
    // Called when the socket was first opened
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        self.sendPong()
        self.connecting = false
        self.connected = true
        self.handleEvent(["name": "connect"])
    }
    
    func setCytubeRoom(room:CytubeRoom) {
        self.cytubeRoom = room
    }
    
}

