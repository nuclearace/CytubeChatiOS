//
//  CytubeSocket.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//

import Foundation

struct socketFrame {
    var name:String!
    var args:AnyObject!
    
    init(name:String, args:AnyObject?) {
        self.name = name
        self.args = args?
    }
    
    func toDict() -> NSDictionary {
        if (self.args != nil) {
            return [
                "name": name,
                "args": args
            ]
        } else {
            return [
                "name": self.name
            ]
        }
    }
}

class EventHandler: NSObject {
    let event:String!
    let callback: ((data:AnyObject?) -> Void)!
    
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
    var socketIOURL:String!
    let session:NSURLSession?
    let room:String!
    let server:String!
    let sioconfigURL:String = "/sioconfig"
    weak var cytubeRoom:CytubeRoom?
    var handlers:NSMutableArray = NSMutableArray()
    
    
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
    func findSocketURL() {
        var jsonError:NSError?
        var url =  "http://" + self.server + self.sioconfigURL
        println("Finding socket URL: " + url)
        
        var request:NSURLRequest = NSURLRequest(URL: NSURL(string: url))
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { [unowned self]
            (res, data, err) -> Void in
            if ((err) != nil) {
                return println(err)
            }
            
            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding) as String
            var mutable = RegexMutable(stringData)
            mutable = mutable["var IO_URLS="] ~= ""
            mutable = mutable["'"] ~= "\""
            mutable[";var IO_URL=(.*)"] ~= ""
            var jsonString = mutable[",IO_URL=(.*)"] ~= ""
            //println(jsonString)
            let data = (jsonString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            var realJSON:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: &jsonError)
            
            if realJSON != nil {
                self.socketIOURL = RegexMutable((realJSON!["ipv4-nossl"] as NSString))["http://"] ~= ""
                self.initHandshake()
            }
        }
    }
    
    // Init the socket
    func initHandshake() {
        println("init handshake")
        let time:NSTimeInterval = NSDate().timeIntervalSince1970 * 1000
        
        //println(self.socketIOURL)
        var endpoint = "http://\(self.socketIOURL)/socket.io/1?t=\(time)"
        
        var handshakeTask:NSURLSessionTask = session!.dataTaskWithURL(NSURL.URLWithString(endpoint), completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) in
            if (error == nil) {
                let stringData:NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                let handshakeToken:NSString = stringData.componentsSeparatedByString(":")[0] as NSString
                println("HANDSHAKE \(handshakeToken)")
                
                self.socketConnect(handshakeToken)
            } else {
                println(error)
                self.cytubeRoom?.handleImminentDelete() {() in
                    var index = roomMng.findRoomIndex(self.room, server: self.server)
                    roomMng.removeRoom(index!)
                }
            }
        })
        handshakeTask.resume()
    }
    
    func socketConnect(token:NSString) {
        socketio = SRWebSocket(URLRequest: NSURLRequest(URL: NSURL(string: "ws://\(self.socketIOURL)/socket.io/1/websocket/\(token)")))
        socketio!.delegate = self
        socketio!.open()
    }
    //
    // End setup WebSocket
    //
    
    func handleEvent(json:AnyObject?) {
        
        let event: NSString = json!["name"] as NSString
        
        for handler in self.handlers {
            if (handler.event == event) {
                if let args:NSDictionary = (json?["args"] as NSArray)[0] as? NSDictionary {
                    handler.executeCallback(args)
                } else {
                    handler.executeCallback(nil)
                }
            }
        }
        
        //        if (event.isEqualToString("rank")) {
        //            //didReceiveFirstRank()
        //            return
        //        } else if (event.isEqualToString("emoteList")) {
        //            return
        //        } else if (event.isEqualToString("setPermissions")) {
        //            return
        //        } else if (event.isEqualToString("userlist")) {
        //            return
        //        } else if (event.isEqualToString("setPlaylistLocked")) {
        //            return
        //        } else if (event.isEqualToString("drinkCount")) {
        //            return
        //        } else if (event.isEqualToString("playlist")) {
        //            return
        //        } else if (event.isEqualToString("setCurrent")) {
        //            return
        //        } else if (event.isEqualToString("usercount")) {
        //            return
        //        }
    }
    
    
    func on(name:String, callback:((data:AnyObject?) -> Void)?) {
        var handler = EventHandler(event: name, callback: callback)
        self.handlers.addObject(handler)
    }
    
    func send(name:String, args:AnyObject?) {
        var frame:socketFrame = socketFrame(name: name, args: args)
        
        var jsonSendError:NSError?
        var jsonSend = NSJSONSerialization.dataWithJSONObject(frame.toDict(), options: NSJSONWritingOptions(0), error: &jsonSendError)
        var jsonString1 = NSString(data: jsonSend!, encoding: NSUTF8StringEncoding)
        println("JSON SENT \(jsonString1)")
        let str:NSString = "5:::\(jsonString1)"
        
        socketio?.send(str)
        
    }
    
    func sendPong() {
        println("SENT PONG")
        self.socketio?.send("2::")
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        // All incoming messages ( socket.on() ) are received in this function. Parsed with JSON
        println("MESSAGE: \(message)")
        
        if (message as NSString == "2::") {
            return self.sendPong()
        }
        
        var jsonError:NSError?
        let messageArray = (message as NSString).componentsSeparatedByString(":::")
        let data:NSData = messageArray[messageArray.endIndex - 1].dataUsingEncoding(NSUTF8StringEncoding)!
        var json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
        
        if json != nil {
            self.handleEvent(json?)
        }
    }
    
    // Called when the socket was closed
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        println("Closed socket because: \(reason)")
        self.cytubeRoom?.handleImminentDelete() {() in
            var index = roomMng.findRoomIndex(self.room, server: self.server)
            roomMng.removeRoom(index!)
        }
    }
    
    // Called when the socket was first opened
    func webSocketDidOpen(webSocket: SRWebSocket!) {
        self.send("initChannelCallbacks", args: nil)
        self.send("joinChannel", args: ["name": self.room])
    }
    
    func setCytubeRoom(room:CytubeRoom) {
        self.cytubeRoom = room
    }
    
}

