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
        
        roomMng.loadRooms()
        let cacheSizeMemory = 4*1024*1024 // 4MB
        let cacheSizeDisk = 32*1024*1024; // 32MB
        let sharedCache = NSURLCache(memoryCapacity: cacheSizeMemory,
            diskCapacity: cacheSizeDisk, diskPath: nil)
        NSURLCache.setSharedURLCache(sharedCache)
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        println("We are about to become inactive")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        println("We entered the background")
        self.backgroundID = application.beginBackgroundTaskWithExpirationHandler() {[weak self] in
            if (self != nil) {
                application.endBackgroundTask(self!.backgroundID)
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            NSLog("Running in the background\n")
            roomMng.saveRooms()
            roomMng.closeRooms()
            application.endBackgroundTask(self.backgroundID)
        })
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        println("Coming back from the background")
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        println("We will become active")
        roomMng.reopenRooms()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        println("We're going down")
        roomMng.saveRooms()
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        NSLog("Recieved memory warning, clearing url cache")
        let sharedCache = NSURLCache.sharedURLCache()
        sharedCache.removeAllCachedResponses()
    }
}

