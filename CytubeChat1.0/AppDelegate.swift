//
//  AppDelegate.swift
//  CytubeChat
//
//  Created by Erik Little on 10/13/14.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window:UIWindow?
    var backgroundID:UIBackgroundTaskIdentifier!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let cacheSizeMemory = 4*1024*1024 // 4MB
        let cacheSizeDisk = 32*1024*1024; // 32MB
        let sharedCache = NSURLCache(memoryCapacity: cacheSizeMemory,
            diskCapacity: cacheSizeDisk, diskPath: nil)
        NSURLCache.setSharedURLCache(sharedCache)
        
        internetReachability.startNotifier()
        dbManger = DatabaseManger()
        roomMng.loadRooms()
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // println("We are about to become inactive")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // println("We entered the background")
        self.backgroundID = application.beginBackgroundTaskWithExpirationHandler() {[weak self] in
            if self != nil {
                application.endBackgroundTask(self!.backgroundID)
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // NSLog("Running in the background\n")
            roomMng.saveRooms()
            roomMng.closeRooms()
            application.endBackgroundTask(self.backgroundID)
        })
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // println("Coming back from the background")
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // println("We will become active")
        roomMng.reopenRooms()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // println("We're going down")
        roomMng.saveRooms()
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        NSLog("Recieved memory warning, clearing url cache")
        let sharedCache = NSURLCache.sharedURLCache()
        sharedCache.removeAllCachedResponses()
    }
}

