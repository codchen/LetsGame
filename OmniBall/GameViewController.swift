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
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
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
    var _scene2modelAdptr: SceneToModelAdapter!
    var _scene2controllerAdptr: SceneToControllerAdapter!
    var _model2sceneAdptr: ModelToSceneAdapter!
    
    @IBOutlet weak var lblHost: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var connectPrompt: UILabel!
    @IBOutlet weak var connectedPeers: UILabel!
//    var hostLabel: UILabel!
    var canStart = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connectionManager = ConnectionManager()
        connectionManager.controller = self
        playBtn.setBackgroundImage(UIImage(named: "300x300_button_battle_0"), forState: UIControlState.Disabled)
        dispatch_async(dispatch_get_main_queue()){
            if (self.connectionManager.peersInGame.getNumPlayers() != self.connectionManager.maxPlayer){
                self.playBtn.enabled = false
                self.connectPrompt.text = "Need to connect to \(self.connectionManager.maxPlayer - 1) more peers!"
            }
            else{
                self.connectPrompt.text = ""
                self.connectedPeers.text = ""
            }
            self.connectPrompt.alpha = 0
        }
        _scene2modelAdptr = SceneToModelAdapter()
        _scene2modelAdptr.model = connectionManager
        _scene2controllerAdptr = SceneToControllerAdapter()
        _scene2controllerAdptr.controller = self
        _model2sceneAdptr = ModelToSceneAdapter()
//        hostLabel = UILabel(frame: CGRect(x: 315, y: 375, width: 300, height: 100))
//        hostLabel.text = "Host: "
//        hostLabel.font = UIFont(name: "Chalkduster", size: 17)
//        self.view.addSubview(hostLabel)
    }
    
    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.Repeat | UIViewAnimationOptions.Autoreverse, animations: {
            self.connectPrompt.alpha = 1
            }, completion: nil)
    }
    
    @IBAction func connect(sender: UIButton) {
    	self.presentViewController(self.connectionManager.browser, animated: true, completion: nil)
    }

    
    @IBAction func play(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) {
            let levelViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LevelViewController") as! LevelViewController
            levelViewController.gameViewController = self
            self.presentViewController(levelViewController, animated: true, completion: nil)
        }
    }
    
    func transitToGame(gameMode: GameMode, gameState: GameState) {
        println("\(connectionManager.gameState.rawValue)")
        switch gameState {
        case .WaitingForReconcil:
            switch gameMode {
            case .HiveMaze:
                connectionManager.gameMode = .HiveMaze
            case .BattleArena:
                connectionManager.gameMode = .BattleArena
            default:
                return
            }
            
            if self.connectionManager.maxPlayer > 1 {
                connectionManager.sendGameStart()
                connectionManager.readyToSendFirstTrip()
            }
//            transitToInstruction()
            
        case .WaitingForStart:
            switch gameMode {
            case .HiveMaze:
                transitToLevelScene()
            case .BattleArena:
                if connectionManager.me.playerID == 0 {
                    transitToBattleArena()
                }
            default:
                return
            }
        default:
            return
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
                scene.scaleMode = .AspectFit
            
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
                println("opening scene")
                let scene = GameBattleScene.unarchiveFromFile("LevelTraining") as! GameBattleScene
                scene._scene2modelAdptr = self._scene2modelAdptr
                scene._scene2controllerAdptr = self._scene2controllerAdptr
                self.connectionManager._model2sceneAdptr.scene = scene
                scene.scaleMode = .AspectFill
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
            println("Current level is " + String(self.currentLevel))
            let scene = GameLevelScene.unarchiveFromFile("Level"+String(self.currentLevel)) as! GameLevelScene
        	scene.currentLevel = self.currentLevel
            scene.slaveNum = self.currentLevel + 1
            scene._scene2modelAdptr = self._scene2modelAdptr
            scene._scene2controllerAdptr = self._scene2controllerAdptr
            self.connectionManager._model2sceneAdptr.scene = scene
            scene.scaleMode = .AspectFill
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentGameScene = scene
            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))

        }
    }
    
    func transitToLevelScene() {
        dispatch_async(dispatch_get_main_queue()) {
            let levelScene = LevelXScene(size: CGSize(width: 1024, height: 768), level: self.currentLevel+1)
            levelScene.scaleMode = .AspectFit
            levelScene._scene2controllerAdptr = self._scene2controllerAdptr
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentView?.presentScene(levelScene, transition: reveal)
        }
    }
    
    func addHostLabel(peerName: String) {
//        hostLabel.backgroundColor = UIColor.whiteColor()
//        hostLabel.font = UIFont(name: "Chalkduster", size: 17)
//        println("Have we done this \(hostLabel.frame)")
//        self.view.addSubview(hostLabel)
        dispatch_async(dispatch_get_main_queue()){
            self.lblHost.text = "Host: " + peerName
        }
//        self.view.drawRect(lblHost.frame)
    }
    

    func updateDestination(message: MessageDestination){
        dispatch_async(dispatch_get_main_queue()) {
            println("received destination")
            self.transitToBattleArena(destination: CGPointMake(CGFloat(message.x), CGFloat(message.y)), rotate: CGFloat(message.rotate), starPos: CGPointMake(CGFloat(message.starX), CGFloat(message.starY)))
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

