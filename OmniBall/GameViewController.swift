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
            println("is nil")
            return nil
        }
    }
    
    class func unarchiveFromFilePresent(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as PresentScene
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

class GameViewController: UIViewController {

    let motionManager: CMMotionManager = CMMotionManager()

    var connectionManager: ConnectionManager!
    var alias: String!
    
    var currentView: SKView!
    var currentGameScene: GameScene!
    
    var currentLevel = -1
    
    @IBOutlet weak var lblHost: UILabel!
    @IBOutlet weak var playBtn: UIButton!
//    var hostLabel: UILabel!
    var canStart = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectionManager = ConnectionManager()
        connectionManager.controller = self
        playBtn.setBackgroundImage(UIImage(named: "300x300_button_battle_0"), forState: UIControlState.Disabled)
        playBtn.enabled = false
//        hostLabel = UILabel(frame: CGRect(x: 315, y: 375, width: 300, height: 100))
//        hostLabel.text = "Host: "
//        hostLabel.font = UIFont(name: "Chalkduster", size: 17)
//        self.view.addSubview(hostLabel)
    }
    
    @IBAction func connect(sender: UIButton) {
    	self.presentViewController(self.connectionManager.browser, animated: true, completion: nil)
    }

    
    @IBAction func play(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) {
            let levelViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LevelViewController") as LevelViewController
            levelViewController.gameViewController = self
            self.presentViewController(levelViewController, animated: true, completion: nil)
        }
    }
    
    func transitToGame(name: String) {
        if connectionManager.gameState == .WaitingForMatch {
            if name == "BattleArena"  {
                connectionManager.gameMode = .BattleArena
            } else if name == "HiveMaze" {
                connectionManager.gameMode = .HiveMaze
            }
            if self.connectionManager.maxPlayer == 1 {
                self.transitToInstruction()
            }
            else{
            self.connectionManager.generateRandomNumber()
            }
        }
    }
    
    func transitToWaitForGameStart(){
        dispatch_async(dispatch_get_main_queue()){
            let scene = WaitingForGameStartScene()
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            scene.controller = self
            if self.currentView == nil {
				self.configureCurrentView()
            }
            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
        }
    }
    
    func configureCurrentView(){
        let skView = SKView(frame: self.view.frame)
        // Configure the view.
        self.view.addSubview(skView)
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = false
        skView.shouldCullNonVisibleNodes = false
        self.currentView = skView
    }
    
    func transitToInstruction(){
        dispatch_async(dispatch_get_main_queue()) {
            let scene = InstructionScene(size: CGSize(width: 2048, height: 1536))
                scene.scaleMode = .AspectFill
                scene.connection = self.connectionManager
                scene.controller = self
                if self.currentView == nil {
                    self.configureCurrentView()
            	}
            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
        }
    }
    
    func transitToBattleArena(destination: CGPoint = CGPointZero, rotate: CGFloat = 1, starPos: CGPoint = CGPointZero){
        dispatch_async(dispatch_get_main_queue()) {
            if self.connectionManager.gameState == GameState.InGame {
                if destination != CGPointZero {
                    self.currentGameScene.updateDestination(destination, desRotation: rotate, starPos: starPos)
                }
            } else {
                let scene = GameBattleScene.unarchiveFromFile("LevelTraining") as GameBattleScene
                scene.scaleMode = .AspectFill
                scene.connection = self.connectionManager
                if self.currentView == nil {
                    self.configureCurrentView()
                }
                if destination != CGPointZero {
                    scene.destPos = destination
                    scene.destRotation = rotate
                    scene.neutralPos = starPos
                }
                self.currentGameScene = scene
                self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
            }
        }
    }
    
    func transitToHiveMaze(){
        dispatch_async(dispatch_get_main_queue()) {
            let scene = GameLevelScene.unarchiveFromFile("Level"+String(self.currentLevel)) as GameLevelScene
        	scene.currentLevel = self.currentLevel
            scene.slaveNum = self.currentLevel + 1
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentGameScene = scene
            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))

        }

    }
    
    func addHostLabel(peerName: String) {

        lblHost.text = "Host: " + peerName
//        hostLabel.backgroundColor = UIColor.whiteColor()
//        hostLabel.font = UIFont(name: "Chalkduster", size: 17)
//        println("Have we done this \(hostLabel.frame)")
//        self.view.addSubview(hostLabel)
        view.setNeedsDisplay()
//        self.view.drawRect(lblHost.frame)
    }
    
    func pause(){
        dispatch_async(dispatch_get_main_queue()) {
            if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
                self.currentGameScene = self.currentView.scene! as GameScene
                self.currentGameScene.paused()
            }
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
    
    func updateDestination(message: MessageDestination){
        transitToBattleArena(destination: CGPointMake(CGFloat(message.x), CGFloat(message.y)), rotate: CGFloat(message.rotate), starPos: CGPointMake(CGFloat(message.starX), CGFloat(message.starY)))
    }
    
    func updateNeutralInfo(message: MessageNeutralInfo, peerPlayerID: Int){
        if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
            self.currentGameScene = self.currentView.scene! as GameScene
            self.currentGameScene.updateNeutralInfo(message, playerID: peerPlayerID)
        }
    }
    
    func updateReborn(message: MessageReborn, peerPlayerID: Int){
        if self.currentView != nil && self.currentView.scene!.className() == "GameScene" {
            self.currentGameScene = self.currentView.scene! as GameScene
            self.currentGameScene.updateReborn(message, peerPlayerID: peerPlayerID)
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

