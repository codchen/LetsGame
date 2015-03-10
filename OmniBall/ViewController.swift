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
        println(file)
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
            
        } else {
            println("is nil")
            return nil
        }
    }
}

extension SKScene {
    func className() -> String{
        return "SKScene"
    }
}

class ViewController: UIViewController {

    let motionManager: CMMotionManager = CMMotionManager()

    var connectionManager: ConnectionManager!
    var alias: String!
    
    var currentView: SKView!
    var currentGameScene: GameScene!

    
    var currentLevel = 0
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.backgroundColor = UIColor(patternImage: UIImage(named: "2048x1536_board_with_boarder")!)
//		btnConnect.titleLabel?.font = UIFont(name: "Marker Felt", size: 50)
//        btnConnect.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
//        btnPlay.titleLabel?.font = UIFont(name: "Marker Felt", size: 50)
//        btnPlay.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        connectionManager = ConnectionManager()
        connectionManager.controller = self
    }
    
    @IBAction func connect(sender: UIButton) {
    	self.presentViewController(self.connectionManager.browser, animated: true, completion: nil)
    }

    
    @IBAction func play(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.connectionManager.maxPlayer > 1 {
                let scene = WaitingForGameStartScene(size: CGSize(width: 2048, height: 1536))
                let skView = SKView(frame: self.view.frame)
                // Configure the view.
                self.view.addSubview(skView)
                skView.showsFPS = true
                skView.showsNodeCount = true
                skView.showsPhysics = true
                
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = false
                skView.shouldCullNonVisibleNodes = false
                
                /* Set the scale mode to scale to fit the window */
                scene.scaleMode = .AspectFill
                
                self.currentView = skView
                skView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
                
                if self.connectionManager.gameState == .WaitingForMatch {
                    self.connectionManager.generateRandomNumber()
                }
            } else {
                self.transitToGame()
            }
        }
    }
	
    func transitToGame(){
        dispatch_async(dispatch_get_main_queue()) {
            let scene = GameScene.unarchiveFromFile("Level"+String(self.currentLevel)) as GameScene
            scene.currentLevel = self.currentLevel
            scene.slaveNum = self.currentLevel + 1
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            if self.currentView == nil {
                let skView = SKView(frame: self.view.frame)
                // Configure the view.
                self.view.addSubview(skView)
                skView.showsFPS = true
                skView.showsNodeCount = true
                skView.showsPhysics = true
                
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = false
                skView.shouldCullNonVisibleNodes = false
                
                self.currentView = skView
            }
            self.currentGameScene = scene
            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
        }
        
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
                self.currentGameScene = self.currentView.scene! as GameScene
                self.currentGameScene.updatePeerPos(message, peerPlayerID: peerPlayerID)
            }
        }
    }
    
    func updatePeerDeath(message: MessageDead, peerPlayerID: Int){
        dispatch_async(dispatch_get_main_queue()){
            if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
                self.currentGameScene = self.currentView.scene! as GameScene
                self.currentGameScene.deletePeerBalls(message, peerPlayerID: peerPlayerID)
            }
        }
    }
    
//    func updateCaptured(message: MessageCapture, peerPlayerID: Int){
//        if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
//            self.currentGameScene = self.currentView.scene! as GameScene
//            self.currentGameScene.updateCaptured(message, playerID: peerPlayerID)
//        }
//    }
    
    func updateNeutralInfo(message: MessageNeutralInfo, peerPlayerID: Int){
        if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
            self.currentGameScene = self.currentView.scene! as GameScene
            self.currentGameScene.updateNeutralInfo(message, playerID: peerPlayerID)
        }
    }
    
    func gameOver(){
        dispatch_async(dispatch_get_main_queue()){
            if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
                self.currentGameScene.gameOver(won: false)
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

