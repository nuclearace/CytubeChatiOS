//
//  ProfileViewController.swift
//  CytubeChat
//
//  Created by Erik Little on 12/20/14.
//

import UIKit
import ImageIO

class ProfileViewController: UIViewController {
    @IBOutlet weak var backBtn:UIBarButtonItem!
    @IBOutlet weak var navBarTitle:UINavigationItem!
    @IBOutlet weak var profileImageView:UIImageView!
    @IBOutlet weak var profileNavBar:UINavigationBar!
    @IBOutlet weak var profileTextView:UITextView!
    var user:CytubeUser?
    
    override func viewDidLoad() {
        if user == nil {
            self.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        
        navBarTitle.title = self.user?.username
        profileTextView.text = self.user?.profileText
        
        if user?.profileImage == nil {
            return
        }
        
        let urlString = user!.profileImage!.absoluteString
        
        NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: user!.profileImage!)) {[weak self] data, res, err in
            if err != nil || self == nil || data == nil {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                // Image is a GIF
                if urlString[".gif$"].matches().count != 0 {
                    let source = CGImageSourceCreateWithData(data!, nil)!
                    var images = [UIImage]()
                    var dur = 0.0
                    
                    for i in 0..<CGImageSourceGetCount(source) {
                        let asCGImage = CGImageSourceCreateImageAtIndex(source, i, nil)
                        let prop = CGImageSourceCopyPropertiesAtIndex(source, i, nil)
                        
                        // Get delay for each frame, so we can play back at proper speed
                        if let gif = (prop as? NSDictionary)?["{GIF}"] as? NSDictionary {
                            if let delay = gif["UnclampedDelayTime"] as? Double {
                                dur += delay
                            }
                        }
                        images.append(UIImage(CGImage: asCGImage!))
                    }
                    
                    self?.profileImageView.animationImages = images
                    self?.profileImageView.animationDuration = dur
                    self?.profileImageView.startAnimating()
                } else {
                    self?.profileImageView.image = UIImage(data: data!)
                    self?.profileImageView.contentMode = UIViewContentMode.ScaleAspectFit
                }
            }
            }.resume()
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
