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
    class func unarchiveFromFile(file : NSString, ifHost: Bool) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            if ifHost{
                let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as combatHostScene
                archiver.finishDecoding()
                return scene
            }
            else{
                let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as combatClientScene
                archiver.finishDecoding()
                return scene
            }
        } else {
            return nil
        }
    }
}

class ViewController: UIViewController {

    let motionManager: CMMotionManager = CMMotionManager()

    var connectionManager: ConnectionManager!
    var currentScene: combatScene!
    var alias: String!
    @IBOutlet weak var btnConnect: UIButton!
    @IBOutlet weak var btnPlay: UIButton!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "2048x1536_board_with_boarder")!)
		btnConnect.titleLabel?.font = UIFont(name: "Marker Felt", size: 50)
        btnConnect.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        btnPlay.titleLabel?.font = UIFont(name: "Marker Felt", size: 50)
        btnPlay.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        connectionManager = ConnectionManager()
        connectionManager.controller = self
    }
    
    @IBAction func showBrowser(sender: UIButton) {
        self.presentViewController(self.connectionManager.browser, animated: true, completion: nil)
    }
    
    @IBAction func showGameScene(sender: UIButton) {
//        if connectionManager.session.connectedPeers.count > 0{
//            var error: NSError?
//            connectionManager.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(1), toPeers: connectionManager.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: &error)
//            if (error != nil){
//                println(error?.description)
//            }
//        }
        
        var scene: combatScene!
        if connectionManager.playerID == 1{
            scene = combatHostScene.unarchiveFromFile("combatScene", ifHost: true) as combatHostScene
        }
        else{
            scene = combatClientScene.unarchiveFromFile("combatScene", ifHost: false) as combatClientScene
        }
        // Configure the view.
        let skView = SKView(frame: self.view.frame)
        self.view.addSubview(skView)
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = false
        
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = false
        
        /* Set the scale mode to scale to fit the window */
        scene.scaleMode = .AspectFill
        
        scene.connection = connectionManager
        connectionManager.state = 1

        skView.presentScene(scene)
        
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates()
        
        scene.motionManager = motionManager
        
        currentScene = scene
    }
	
    
    func updatePeerPos(data: NSData, peer: MCPeerID) {
        dispatch_async(dispatch_get_main_queue()) {
            //var msg = NSString(data: data, encoding: NSUTF8StringEncoding)
            
            if self.currentScene != nil{
                if self.currentScene.identity == "Host"{
                    if contains(self.currentScene.peerList, "ball" + peer.displayName){
                        self.currentScene.updatePeers(data, peer: "ball" + peer.displayName)
//                        println("bibibi")
                    } else {
                        self.currentScene.addPlayer(data, peer: "ball" + peer.displayName)
//                    	println("oh bi")
                    }
                }
                else {
                    var message = UnsafePointer<MessageMove>(data.bytes).memory
                    println("\(message.number) + is what")
                    println(self.currentScene.peerList)
                    if contains(self.currentScene.peerList, String(message.number)){
                        self.currentScene.updatePeers(data, peer: "ball" + peer.displayName)
//                        println("bi")
                    } else {
                        self.currentScene.addPlayer(data, peer: "ball" + peer.displayName)
                        println("bibi")
                    }
                }
            }
        }
    }
    
//    func updatePeerDrop(message: ConnectionManager.MessageDrop, peer: MCPeerID) {
//        dispatch_async(dispatch_get_main_queue()){
//            if self.currentScene != nil {
//                self.currentScene.dropPlayer(message, peer: peer.displayName)
//            }
//        }
//    }
//    
//    func addScore(message: ConnectionManager.MessageAddScore) {
//        self.currentScene.addScore(message.name)
//    }

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

