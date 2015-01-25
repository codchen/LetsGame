//
//  ViewController.swift
//  try
//
//  Created by Xiaoyu Chen on 1/13/15.
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

class ViewController: UIViewController {

    let motionManager: CMMotionManager = CMMotionManager()

    var connectionManager: ConnectionManager!
    var currentScene: GameScene!
    var alias: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectionManager = ConnectionManager()
        connectionManager.controller = self
    }
    
    @IBAction func showBrowser(sender: UIButton) {
        self.presentViewController(self.connectionManager.browser, animated: true, completion: nil)
    }
    
    @IBAction func showGameScene(sender: UIButton) {
                if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
                    // Configure the view.
                    let skView = SKView(frame: self.view.frame)
                    self.view.addSubview(skView)
                    skView.showsFPS = true
                    skView.showsNodeCount = true
                    skView.showsPhysics = true
                    
        
                    /* Sprite Kit applies additional optimizations to improve rendering performance */
                    skView.ignoresSiblingOrder = true
        
                    /* Set the scale mode to scale to fit the window */
                    scene.scaleMode = .AspectFill
                    
                    scene.connection = connectionManager
        
                    skView.presentScene(scene)
        
                    motionManager.accelerometerUpdateInterval = 0.05
                    motionManager.startAccelerometerUpdates()
                    
                    scene.motionManager = motionManager
                    
                    currentScene = scene
                    

                }
    }
	
    
    func updatePeerPos(message: ConnectionManager.MessageMove, peer: MCPeerID) {
        
//        if self.currentScene != nil{
//            if let existed = self.currentScene.childNodeWithName("dot" + peer.displayName){
//                self.currentScene.updatePeerPos(posX, posY: posY, dx: dx, dy: dy, rotation: rotation, peer: existed)
//            } else {
//                self.currentScene.addPlayer(posX, posY: posY, name: peer.displayName)
//            }
//        }

        dispatch_async(dispatch_get_main_queue()) {
            //var msg = NSString(data: data, encoding: NSUTF8StringEncoding)
            if self.currentScene != nil{
                if let existed = self.currentScene.childNodeWithName("dot" + peer.displayName){
                    self.currentScene.updatePeerPos(message, peer: existed)
                } else {
                    self.currentScene.addPlayer(message.posX, posY: message.posY, name: peer.displayName)
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

