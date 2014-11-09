//
//  ChatLinkController.swift
//  CytubeChat
//
//  Created by Erik Little on 11/8/14.
//  Copyright (c) 2014 Erik Little. All rights reserved.
//

import UIKit

class ChatLinkController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView:UIWebView!
    var link:NSURL!
    
    @IBAction func backButtonClicked() {
        self.webView = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        let req = NSURLRequest(URL: self.link)
        self.webView.loadRequest(req)
    }
}
