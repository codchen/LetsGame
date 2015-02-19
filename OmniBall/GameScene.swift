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

struct Opponent {
    var nodes: [SKSpriteNode]
    var updated: [Bool]
    var info: [nodeInfo]
    var color: PlayerColors
    var lastCount: UInt32
    var deleteIndex: Int
}

enum PlayerColors: Int{
    case Green = 0, Red, Yellow, Blue
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    
    var myNodes: [SKSpriteNode] = []
    var selected: Bool = false
    var locked: Bool = false
    var selectedNode: SKSpriteNode!
    
    // Opponents Setting
    var opponents: Dictionary<Int, Opponent> = Dictionary<Int, Opponent>()
    
    var myDeadNodes: [Int] = []
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    var currentTime: NSDate!
    
    var c: UInt32 = 0
//    var lastCount: UInt32 = 0
    
    //node info
//    var currentInfo: nodeInfo!
    var offset: CGFloat!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    
    var playerColor: PlayerColors!
    var gameOver: Bool = false
    
    
    
    override func didMoveToView(view: SKView) {
        
        connection.gameState = .InGame
        
        playerColor = PlayerColors(rawValue: connection.playerID)
        setUpPlayerColors(playerColor, playerID: connection.playerID)
        println("playerID is \(connection.playerID)")
        
        for var index = 0; index < connection.maxPlayer; ++index {
            if connection.playerID != index {
                let color = PlayerColors(rawValue: index)
                opponents[index] = Opponent(nodes: [SKSpriteNode](), updated: [Bool](), info: [nodeInfo](), color: color!, lastCount: UInt32(0), deleteIndex: -1)
                setUpPlayerColors(color!, playerID: index)
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
    
    func closeEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        offset = point1.distanceTo(point2)
        if offset >= 10{
            return false
        }
        return true
    }
    
    func update_peer_dead_reckoning(){
        for (id, var player) in opponents{
            
            let currentOppNodes = player.nodes
            
            for var index = 0; index < player.updated.count; ++index {
                if player.updated[index] == true {
                    
                    let currentNodeInfo = player.info[index]
                    
                    if closeEnough(CGPoint(x: currentNodeInfo.x, y: currentNodeInfo.y), point2: currentOppNodes[index].position) == true {
                        currentOppNodes[index].physicsBody!.velocity = CGVector(dx: currentNodeInfo.dx, dy: currentNodeInfo.dy)
                    }
                    else {
                        currentOppNodes[index].physicsBody!.velocity = CGVector(dx: currentNodeInfo.dx + (currentNodeInfo.x - currentOppNodes[index].position.x), dy: currentNodeInfo.dy + (currentNodeInfo.y - currentOppNodes[index].position.y))
                    }
                    
                    player.updated[index] = false
                }

            }
            opponents[id] = player
        }
    }
    
    func deleteMyNode(index: Int){
        myNodes[index].removeFromParent()
        myNodes.removeAtIndex(index)
        sendDead(index)
    }
    
    func deleteOpponent(playerID: Int, index: Int){
        opponents[playerID]?.nodes[index].removeFromParent()
        opponents[playerID]?.nodes.removeAtIndex(index)
        opponents[playerID]?.info.removeAtIndex(index)
        opponents[playerID]?.updated.removeAtIndex(index)
    }
    
    func withinBorder(pos: CGPoint) -> Bool{
        if pos.x < 0 || pos.x > size.width || pos.y < margin || pos.y > size.height - margin{
            return false
        }
        return true
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        if !gameOver {
            checkGameOver()
        }
        
        for var index = 0; index < self.myNodes.count; ++index{
            if withinBorder(myNodes[index].position) == false{
                self.myDeadNodes.insert(index, atIndex: 0)
            }
        }
        for index in self.myDeadNodes{
            self.deleteMyNode(index)
        }
        
        self.myDeadNodes = []
        
        for (id, var opponent) in opponents {
            if opponent.deleteIndex != -1 {
                deleteOpponent(id, index: opponent.deleteIndex)
                opponent.deleteIndex = -1
                opponents[id] = opponent
            }
        }
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        sendMove()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        //node1.physicsBody?.applyForce(CGVector(dx: -50, dy: 0))
        if locked == false{
            let touch = touches.anyObject() as UITouch
            let loc = touch.locationInNode(self)
            if selected == false{
                for node in myNodes{
                    if node.containsPoint(loc){
                        selectedNode = node
                        selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(playerColor, isSelected: true))
                        selected = true
                        break
                    }
                }
            }
            else {
                selectedNode.physicsBody?.velocity = CGVector(dx: 2*(loc.x - selectedNode.position.x), dy: 2*(loc.y - selectedNode.position.y))
                selected = false
                selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(self.playerColor, isSelected: false))
                selectedNode = nil
                //locked = true
                sendMove()
            }
        }
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
    
    func sendDead(index: Int){
        println("I'm dead")
        connection.sendDeath(index)
    }
    
    func sendMove(){
        for var index = 0; index < self.myNodes.count; ++index{
            connection.sendMove(Float(myNodes[index].position.x), y: Float(myNodes[index].position.y), dx: Float(myNodes[index].physicsBody!.velocity.dx), dy: Float(myNodes[index].physicsBody!.velocity.dy), count: c, index: UInt16(index), dt: NSDate().timeIntervalSince1970)
                c++
        }
    }
    
    override func className() -> String{
        return "GameScene"
    }
}
