//
//  CytubeSocket.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//  Copyright (c) 2014 Tracy Cage Industries. All rights reserved.
//

import Foundation

class CytubeSocket: NSObject, SRWebSocketDelegate {
    
    var socketio:SRWebSocket?
    let socketIOURL:String!
    let session:NSURLSession?
    let room:String!
    let server:String!
    let sioconfigURL:String = "/sioconfig"
    weak var cytubeRoom:CytubeRoom?
    
    
    init(server:String, room:String) {
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
        self.findSocketURL()
    }
    
    deinit {
        println("CytubeSocket for room \(self.room) is being deint")
    }
    
    // Finds the correct socket URL
    func findSocketURL() {
        var url =  "http://" + self.server + self.sioconfigURL
        println("Finding socket URL: " + url)
        func parseData(data:NSData) {
           var stringData = NSString(data: data, encoding: NSUTF8StringEncoding) as String
            println(stringData)
        }
        
        var request:NSURLRequest = NSURLRequest(URL: NSURL(string: url))
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) { (res, data, err) -> Void in
            if ((err) != nil) {
                return println(err)
            }
            
            parseData(data as NSData)
        }
    }
    
    // Init the socket
    func initHandshake() {
        println("init handshake")
        let time:NSTimeInterval = NSDate().timeIntervalSince1970 * 1000
        
        println(server)
        var endpoint = "http://\(server)/socket.io/1?t=\(time)"
        
        var handshakeTask:NSURLSessionTask = session!.dataTaskWithURL(NSURL.URLWithString(endpoint), completionHandler: { (data:NSData!, response:NSURLResponse!, error:NSError!) in
            if (error == nil) {
                let stringData:NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                let handshakeToken:NSString = stringData.componentsSeparatedByString(":")[0] as NSString
                println("HANDSHAKE \(handshakeToken)")
                
                self.socketConnect(handshakeToken)
            } else {
                println(error)
            }
        })
        handshakeTask.resume()
    }
    
    
    func socketConnect(token:NSString) {
        socketio = SRWebSocket(URLRequest: NSURLRequest(URL: NSURL(string: "ws://\(server)/socket.io/1/websocket/\(token)")))
        socketio!.delegate = self
        socketio!.open()
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        // All incoming messages ( socket.on() ) are received in this function. Parsed with JSON
        println("MESSAGE: \(message)")
        
        var jsonError:NSError?
        let messageArray = (message as NSString).componentsSeparatedByString(":::")
        let data:NSData = messageArray[messageArray.endIndex - 1].dataUsingEncoding(NSUTF8StringEncoding)!
        var json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
        
        if json != nil {
            let event: NSString = json!["name"] as NSString
            
            if (event.isEqualToString("rank")) {
                //didReceiveFirstRank()
                return
            } else if (event.isEqualToString("emoteList")) {
                return
            } else if (event.isEqualToString("setPermissions")) {
                return
            } else if (event.isEqualToString("userlist")) {
                return
            } else if (event.isEqualToString("setPlaylistLocked")) {
                return
            } else if (event.isEqualToString("drinkCount")) {
                return
            } else if (event.isEqualToString("playlist")) {
                return
            } else if (event.isEqualToString("setCurrent")) {
                return
            } else if (event.isEqualToString("usercount")) {
                return
            }
            
            let args:NSDictionary = (json!["args"] as NSArray)[0] as NSDictionary
            
        }
    }
    
    func setCytubeRoom(room:CytubeRoom) {
        self.cytubeRoom = room
    }
    
}

