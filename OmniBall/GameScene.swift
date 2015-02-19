//
//  GameScene.swift
//  TestForCollision
//
//  Created by Xiaoyu Chen on 2/2/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity
import CoreMotion

struct nodeInfo {
    var x: CGFloat
    var y: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var dt: CGFloat
    var index: UInt16
}

enum PlayerColors: Int{
    case Green = 0, Red, Yellow, Blue
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    
//    var myNodes: [SKSpriteNode] = []
    var selected: Bool = false
    var locked: Bool = false
    var selectedNode: SKSpriteNode!
    
    // Opponents Setting
    var myNodes: MyNodes!
    var opponentsWrapper: OpponentsWrapper!
    
    var myDeadNodes: [Int] = []
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    var currentTime: NSDate!
    
    var c: UInt32 = 0
//    var lastCount: UInt32 = 0
    
    //node infof
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    
    var gameOver: Bool = false
    
    override func didMoveToView(view: SKView) {
        
        connection.gameState = .InGame
        myNodes = MyNodes(connection: connection, scene: self)
        println("playerID is \(connection.playerID)")
        
        opponentsWrapper = OpponentsWrapper()
        for var index = 0; index < connection.maxPlayer; ++index {
            if connection.playerID != index {
                let opponent = OpponentNodes(id: index, scene: self)
                opponentsWrapper.addOpponent(opponent)
            }
        }
        
        /* Setup your scene here */

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)

        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
    }
    
    func randomPos() -> CGPoint{
        return CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 200, max: size.height - 2 * margin - 200))
    }
    
    func update_peer_dead_reckoning(){
		opponentsWrapper.update_peer_dead_reckoning()
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        if !gameOver {
            checkGameOver()
        }
        
        myNodes.checkDead()
        opponentsWrapper.checkDead()
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        myNodes.sendMove()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        //node1.physicsBody?.applyForce(CGVector(dx: -50, dy: 0))
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        myNodes.touchesHappened(loc)
    }
    
    func deletePeerBalls(message: MessageDead, peerPlayerID: Int) {
        opponents[peerPlayerID]?.deleteIndex = message.index
    }
    
    func checkGameOver() {
        if myNodes.count == 0 {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: false)
        }
    }
    
    func gameOver(#won: Bool) {
        connection.gameState = .Done
        connection.playerID = 0
        connection.randomNumbers.removeAll(keepCapacity: true)
        connection.receivedAllRandomNumber = false
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.scaleMode = scaleMode
        gameOverScene.controller = connection.controller
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        self.currentTime = NSDate()
        var player = opponents[peerPlayerID]
        if (message.count > player?.lastCount){
            player?.lastCount = message.count
            player?.info[Int(message.index)] = nodeInfo(x: CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index)
            player?.updated[Int(message.index)] = true
        }
        opponents[peerPlayerID] = player
    }
    

    
    override func className() -> String{
        return "GameScene"
    }
}
