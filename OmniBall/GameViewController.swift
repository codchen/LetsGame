//
//  GameViewController.swift
//  RawGame
//
//  Created by Xiaoyu Chen on 1/6/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity
import CoreMotion

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {
    let motionManager: CMMotionManager = CMMotionManager()
    override func viewDidLoad() {
        super.viewDidLoad()
//
//        self.peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
//        self.session = MCSession(peer: peerID)
//        self.session.delegate = self
//        
//        // create the browser viewcontroller with a unique service name
//        self.browser = MCBrowserViewController(serviceType:serviceType,
//            session:self.session)
//        
//        self.browser.delegate = self;
//        
//        self.assistant = MCAdvertiserAssistant(serviceType:serviceType,
//            discoveryInfo:nil, session:self.session)
//        
//        // tell the assistant to start advertising our fabulous chat
//        self.assistant.start()
//        self.presentViewController(self.browser, animated: true, completion: nil)
        
        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
            
            motionManager.accelerometerUpdateInterval = 0.05
            motionManager.startAccelerometerUpdates()
            
            scene.motionManager = motionManager
        }
    }

    

    
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    deinit{
        motionManager.stopAccelerometerUpdates()
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
}
