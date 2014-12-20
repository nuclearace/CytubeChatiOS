//
//  ProfileViewController.swift
//  CytubeChat
//
//  Created by Erik Little on 12/20/14.
//

import UIKit

class ProfileViewController: UIViewController {
    @IBOutlet weak var backBtn:UIBarButtonItem!
    @IBOutlet weak var navBarTitle:UINavigationItem!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileNavBar:UINavigationBar!
    @IBOutlet weak var profileTextView: UITextView!
    var user:CytubeUser?
    
    override func viewDidLoad() {
        self.navBarTitle.title = self.user?.username
        self.profileTextView.text = self.user?.profileText
        if (self.user?.profileImage != nil) {
            NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: self.user!.profileImage!),
                queue: NSOperationQueue.mainQueue()) {[weak self] res, data, err in
                    if (err != nil) {
                        return
                    }
                    let image = UIImage(data: data)
                    image?.resizableImageWithCapInsets(image!.capInsets,
                        resizingMode: UIImageResizingMode.Stretch)
                    self?.profileImageView.image = image
                    self?.profileImageView.startAnimating()
            }
        }
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
