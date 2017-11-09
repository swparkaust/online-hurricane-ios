//
//  GameViewController.swift
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2014. 8. 31..
//  Copyright (c) 2014년 Ryuhyun Factory. All rights reserved.
//

import UIKit
import SpriteKit
import iAd

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData!)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, ADBannerViewDelegate {
    
    var iAdBanner = ADBannerView()
    var bannerVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as! SKView
            skView.showsFPS = false
            skView.showsNodeCount = false
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            
            var mainScene = LogoScene(size: CGSize(width: 768, height: 1024), index: 0)
        
            /* Set the scale mode to scale to fit the window */
            mainScene.scaleMode = .AspectFill
            mainScene.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            
            skView.presentScene(mainScene)
//        }
        
        //iAd banner
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showiAdBanner", name: "showiAdBanner", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "hideiAdBanner", name: "hideiAdBanner", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        iAdBanner.frame = CGRectMake(0, -iAdBanner.frame.size.height, self.view.frame.width, iAdBanner.frame.size.height)
        iAdBanner.delegate = self
        bannerVisible = false
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func showiAdBanner() {
        if(bannerVisible == false) {
            
            if(iAdBanner.superview == nil) {
                self.view.addSubview(iAdBanner)
            }
            
            UIView.beginAnimations("iAdBannerShow", context: nil)
            iAdBanner.frame = CGRectOffset(iAdBanner.frame, 0, iAdBanner.frame.size.height)
            UIView.commitAnimations()
            
            bannerVisible = true
        }
    }
    
    func hideiAdBanner() {
        if(bannerVisible == true) {
            UIView.beginAnimations("iAdBannerHide", context: nil)
            iAdBanner.frame = CGRectOffset(iAdBanner.frame, 0, -iAdBanner.frame.size.height)
            UIView.commitAnimations()
            bannerVisible = false
        }
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if(bannerVisible == true) {
            UIView.beginAnimations("iAdBannerHide", context: nil)
            banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height)
            UIView.commitAnimations()
            bannerVisible = false
        }
    }
}
