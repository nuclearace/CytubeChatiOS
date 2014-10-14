//
//  ThirdViewController.swift
//  CytubeChat1.0
//
//  Created by Erik Little on 10/13/14.
//  Copyright (c) 2014 Tracy Cage Industries. All rights reserved.
//

import UIKit

class ThirdViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var navBarTitle:UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnClicked(btn:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}