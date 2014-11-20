//
//  ChatLinkController.swift
//  CytubeChat
//
//  Created by Erik Little on 11/8/14.
//

import UIKit

class ChatLinkController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView:UIWebView!
    @IBOutlet weak var navBarTitle:UINavigationItem!
    var link:NSURL!
    
    @IBAction func backButtonClicked() {
        self.webView.loadHTMLString("", baseURL: nil)
        self.webView = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        self.navBarTitle.title = self.link.host
        let req = NSURLRequest(URL: self.link)
        self.webView.loadRequest(req)
    }
}
