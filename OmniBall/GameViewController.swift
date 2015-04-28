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
    
    func AddChild(node: SKNode) {
        if node.parent == nil {
            addChild(node)
        }
    }
    
    func RemoveFromParent() {
        if parent != nil {
            removeFromParent()
        }
    }
}

extension SKScene {
    func className() -> String{
        return "SKScene"
    }
}

class GameViewController: DifficultyController {

    //let motionManager: CMMotionManager = CMMotionManager()

    //var connectionManager: ConnectionManager!
    var alias: String!
    var playerNum: Int!
//    var currentView: SKView!
//    var currentGameScene: GameScene!
    
    //var currentLevel = 0
    
    @IBOutlet weak var instructionText: UILabel!
    @IBOutlet weak var playerIcon2: UIImageView!
    
    @IBOutlet weak var playerIcon3: UIImageView!
    @IBOutlet weak var lblHost: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var player1: UILabel!
    @IBOutlet weak var player2: UILabel!
    @IBOutlet weak var player3: UILabel!
    @IBOutlet weak var exitBtn: UIButton!
    var playerList: [UILabel!] = []
//    var hostLabel: UILabel!
//    var canStart = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectionManager = ConnectionManager(pNum: playerNum, control: self)
        dispatch_async(dispatch_get_main_queue()){
            self.playBtn.enabled = false
        }
        setHostUI()
        player1.text = connectionManager.me.getName()
        playerList.append(player1)
        if playerNum > 1 {
            player2.text = ""
            playerList.append(player2)
            if playerNum > 2 {
                player3.text = ""
                playerList.append(player3)
            }
            else {
                player3.removeFromSuperview()
                playerIcon3.removeFromSuperview()
            }
        }
        else{
            player2.removeFromSuperview()
            playerIcon2.removeFromSuperview()
            player3.removeFromSuperview()
            playerIcon3.removeFromSuperview()
        }
    }
    //disable animation
    override func viewDidAppear(animated: Bool) {
        println("Called?")
        if connectionManager.gameState != .InViewController {
            if connectionManager.peersInGame.getNumPlayers() < connectionManager.maxPlayer {
                connectionManager.startConnecting()
                connectionManager.gameState = .WaitingForStart
                connectionManager.diffController = nil
            }
        }
    }
    
    @IBAction func play(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) {
        	//self.connectionManager.readyToChooseGameMode()
            self.connectionManager.gameState = .InLevelViewController
            let levelViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LevelViewController") as LevelViewController
            levelViewController.gameViewController = self
            self.presentViewController(levelViewController, animated: true, completion: nil)
        }
    }
    @IBAction func exit(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        connectionManager.gameState = .InViewController
        connectionManager.stopConnecting()
        self.connectionManager.session.disconnect()
    }
    
//    func transitToGame(name: String) {
//        println("\(connectionManager.gameState.rawValue)")
//        if connectionManager.gameState == .WaitingForStart {
//            if name == "BattleArena"  {
//                connectionManager.gameMode = .BattleArena
//            } else if name == "HiveMaze" {
//                connectionManager.gameMode = .HiveMaze
//            } else if name == "PoolArena" {
//                connectionManager.gameMode = .PoolArena
//            } else if name == "HiveMaze2" {
//                connectionManager.gameMode = .HiveMaze2
//            }
//            
//            if self.connectionManager.maxPlayer == 1 {
//                self.transitToInstruction()
//            } else {
//                connectionManager.sendGameStart()
//                connectionManager.readyToSendFirstTrip()
//            }
//        }
//    }
//    
//    func transitToWaitForGameStart(){
//        dispatch_async(dispatch_get_main_queue()){
//            let scene = WaitingForGameStartScene()
//            scene.scaleMode = .AspectFill
//            scene.connection = self.connectionManager
//            scene.controller = self
//            if self.currentView == nil {
//				self.configureCurrentView()
//            }
//            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
//        }
//    }
//    
//    func configureCurrentView(){
//        let skView = SKView(frame: self.view.frame)
//        // Configure the view.
//        self.view.addSubview(skView)
//        skView.showsFPS = false
//        skView.showsNodeCount = false
//        skView.showsPhysics = false
//        skView.ignoresSiblingOrder = false
//        skView.shouldCullNonVisibleNodes = false
//        self.currentView = skView
//    }
//    
//    func transitToInstruction(){
//        dispatch_async(dispatch_get_main_queue()) {
//            let scene = InstructionScene(size: CGSize(width: 2048, height: 1536))
//                scene.scaleMode = .AspectFit
//                scene.connection = self.connectionManager
//                scene.controller = self
//                if self.currentView == nil {
//                    self.configureCurrentView()
//            	}
//            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
//        }
//    }
//    
//    func transitToBattleArena(destination: CGPoint = CGPointZero, rotate: CGFloat = 1, starPos: CGPoint = CGPointZero){
//        dispatch_async(dispatch_get_main_queue()) {
//            if self.connectionManager.gameState == GameState.InGame {
//                if destination != CGPointZero {
//                    self.currentGameScene.updateDestination(destination, desRotation: rotate, starPos: starPos)
//                }
//            } else {
//                let scene = GameBattleScene.unarchiveFromFile("LevelTraining") as GameBattleScene
//                scene.scaleMode = .AspectFill
//                scene.connection = self.connectionManager
//                if self.currentView == nil {
//                    self.configureCurrentView()
//                }
//                if destination != CGPointZero {
//                    scene.destPos = destination
//                    scene.destRotation = rotate
//                    scene.neutralPos = starPos
//                }
//                self.currentGameScene = scene
//                self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
//            }
//        }
//    }
//    
//    func transitToHiveMaze(){
//        dispatch_async(dispatch_get_main_queue()) {
//            self.connectionManager.maxLevel = 4
//            let scene = GameLevelScene.unarchiveFromFile("Level"+String(self.currentLevel)) as GameLevelScene
//        	scene.currentLevel = self.currentLevel
//            scene.slaveNum = self.currentLevel
//            scene.scaleMode = .AspectFill
//            scene.connection = self.connectionManager
//            if self.currentView == nil {
//                self.configureCurrentView()
//            }
//            self.currentGameScene = scene
//            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
//
//        }
//    }
//    
//    func transitToHiveMaze2(){
//        dispatch_async(dispatch_get_main_queue()) {
//            self.connectionManager.maxLevel = 6
//            let scene = GameLevelScene.unarchiveFromFile("HLevel"+String(self.currentLevel)) as GameLevelScene
//            scene.currentLevel = self.currentLevel
//            scene.slaveNum = self.currentLevel
//            scene.scaleMode = .AspectFill
//            scene.connection = self.connectionManager
//            if self.currentView == nil {
//                self.configureCurrentView()
//            }
//            self.currentGameScene = scene
//            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
//            
//        }
//    }
//    
//    func transitToPoolArena() {
//        dispatch_async(dispatch_get_main_queue()) {
//            println("called 2")
//            let scene = GamePoolScene.unarchiveFromFile("PoolArena") as GamePoolScene
//            scene.slaveNum = 7
//            scene.scaleMode = .AspectFill
//            scene.connection = self.connectionManager
//            if self.currentView == nil {
//                self.configureCurrentView()
//            }
//            self.currentGameScene = scene
//            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
//        }
//    }
    
//    func addHostLabel(peerName: String) {
//        dispatch_async(dispatch_get_main_queue()){
//            self.lblHost.text = "Host: " + peerName
//        }
//    }
//    
//    func deletePlayerLabel(peerName: String) {
//        dispatch_async(dispatch_get_main_queue()){
//            self.lblHost.text = ""
//            self.playBtn.enabled = false
//            self.playBtn.alpha = 0.1
//            for var i = 0; i < self.playerList.count; ++i {
//                if self.playerList[i].text == peerName {
//                    if i == 1 {
//                        self.playerList[i].text = self.playerList[i + 1].text
//                        self.playerList[i + 1].text = ""
//                    }
//                    else{
//                        self.playerList[i].text = ""
//                    }
//                    break
//                }
//            }
//        }
//
//    }
    
    func setHostUI() {
        dispatch_async(dispatch_get_main_queue()){
            let isHost = (self.connectionManager.peersInGame.getNumPlayers() == self.connectionManager.peersInGame.numOfPlayers && self.connectionManager.me.playerID == 0) || self.playerNum == 1
            let isConnecting = self.connectionManager.peersInGame.getNumPlayers() < self.connectionManager.peersInGame.numOfPlayers
            if isHost {
                self.playBtn.enabled = true
                self.instructionText.text = "You are the host. Tap \"Play\" to start game!"
                self.playBtn.alpha = 0.5
                UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.Repeat | UIViewAnimationOptions.Autoreverse | UIViewAnimationOptions.AllowUserInteraction, animations: {
                    self.playBtn.alpha = 1
                    }, completion: nil)
            } else {
                self.playBtn.enabled = false
                self.playBtn.alpha = 0
                self.playBtn.layer.removeAllAnimations()
                self.instructionText.alpha = 1
                if isConnecting {
                    self.instructionText.text = "Waiting for other players... "
                } else {
                    self.instructionText.text = "Waiting for the host to start game..."
                }
                UIView.animateWithDuration(1, delay: 0, options: UIViewAnimationOptions.Repeat | UIViewAnimationOptions.Autoreverse, animations: {
                    self.instructionText.alpha = 0.5
                    }, completion: nil)
            }
            
            var name = ""
            if !isConnecting {
                for peer in self.connectionManager.peersInGame.peers {
                    if peer.playerID == 0 {
                        name = peer.getName()
                    }
                }
            }
            if self.playerNum == 1 {
                name = self.connectionManager.me.getName()
            }
            self.lblHost.text = "Host: " + name
            println("Host: "+name)
        }

    }
//
//    func clearCurrentView() {
//        self.currentView = nil
//    }
    
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
    
//    deinit{
//        motionManager.stopAccelerometerUpdates()
//    }
    
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

