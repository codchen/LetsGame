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

enum ScrollDirection: Int{
    case up = 0, down, left, right
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    var scrollDirection: ScrollDirection!
    var scrolling = false
    var anchorPointVel = CGVector(dx: 0, dy: 0)
    var scrollingFrameDuration = CGFloat(30)
    
    var subscene_index = 1
    let subscene_count_horizontal = 2
    let subscene_count_vertical = 2
    
    // Opponents Setting
    var myNodes: MyNodes!
    var opponentsWrapper: OpponentsWrapper!
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    let protectionInterval: Double = 1000
    var lastCaptured: [Double] = [0, 0, 0]
    
    var gameOver: Bool = false
    
    override func didMoveToView(view: SKView) {
        
        size = CGSize(width: 1024, height: 768)
        connection.gameState = .InGame
        myNodes = MyNodes(connection: connection, scene: self)
        
        println("playerID is \(connection.playerID)")
        opponentsWrapper = OpponentsWrapper()
        setupNeutral()
        for var index = 0; index < connection.maxPlayer; ++index {
            println("int(connection.playerID) \(Int(connection.playerID)) \(connection.playerID)")
            if Int(connection.playerID) != index {
                println("uint16(index) \(UInt16(index)) \(index)")
                let opponent = OpponentNodes(id: UInt16(index), scene: self)
                opponentsWrapper.addOpponent(opponent)
            }
        }
        
        /* Setup your scene here */

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
    }
    
    func setupNeutral(){
        var node1: SKSpriteNode!
        enumerateChildNodesWithName("neutral*"){node, _ in
            node1 = node as SKSpriteNode
            node1.physicsBody?.restitution = 1
            node1.physicsBody?.linearDamping = 0
            node1.physicsBody?.categoryBitMask = physicsCategory.target
            node1.physicsBody?.contactTestBitMask = physicsCategory.Me
        }
    }

    

    func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.contactTestBitMask | contact.bodyB.contactTestBitMask
        if collision == physicsCategory.Me | physicsCategory.target{
            var node: SKSpriteNode = contact.bodyA.node! as SKSpriteNode
            if contact.bodyB.node!.name == "neutral*"{
                node = contact.bodyB.node! as SKSpriteNode
            }
            let name: NSString = node.name! as NSString
            let index: Int = name.substringFromIndex(7).toInt()!
            let now = NSDate()
            if (now.timeIntervalSince1970 >= lastCaptured[index] + protectionInterval){
                if myNodes.capturedIndex[index] == -1{
                    myNodes.capture(index, target: node)
                    for (peer, nodes) in opponentsWrapper.opponents{
                        if nodes.capturedIndex[index] != -1{
                            nodes.decapture(index)
                        }
                    }
                    //sendCaptured(index)
                }
            }
        }
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
        moveAnchor()
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        myNodes.sendMove()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {

        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        
        if myNodes.isSelected == false {
            myNodes.touchesBegan(loc)
            if myNodes.isSelected == false && scrolling == false {
                setSrollDirection(loc)
            }
        } else {
            myNodes.launchPoint = loc
            myNodes.launchTime = NSDate()
        }
    }

    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        
        if myNodes.isSelected == true && myNodes.launchTime != nil && myNodes.launchPoint != nil{
            
//            enumerateChildNodesWithName("*"){node, _ in
//                println("\(node.name): \(node.physicsBody!.categoryBitMask), \(node.physicsBody!.contactTestBitMask)\n")
//            }
            
			myNodes.touchesEnded(loc)
        }
            
        else if scrollDirection != nil{
            var swipeValid: Bool = true
            switch scrollDirection!{
            case .up:
                if (loc.y < -anchorPoint.y * size.height + size.height - 250) && subscene_index != 3 && subscene_index != 4 {
                    scroll(scrollDirection)
                }
            case .down:
                if (loc.y > -anchorPoint.y * size.height + 250) && subscene_index != 1 && subscene_index != 2 {
                    scroll(scrollDirection)
                }
            case .left:
                if (loc.x > -anchorPoint.x * size.width + 250) && subscene_index != 1 && subscene_index != 3 {
                    scroll(scrollDirection)
                }
            case .right:
                if (loc.x < -anchorPoint.x * size.width + size.width - 250) && subscene_index != 2 && subscene_index != 4 {
                    scroll(scrollDirection)
                }
            default:
                println("error scrolling")
            }
            
        }
    }
    
    func setSrollDirection(location: CGPoint) {
        if location.y > (-anchorPoint.y * size.height + size.height - 150){
            scrollDirection = .up
        }
        else if location.y < (-anchorPoint.y * size.height + 150){
            scrollDirection = .down
        }
        else if location.x < (-anchorPoint.x * size.width + 150){
            scrollDirection = .left
        }
        else if location.x > (-anchorPoint.x * size.width + size.width - 150){
            scrollDirection = .right
        }
        println("\(location.x), \(location.y), \(anchorPoint.x), \(anchorPoint.y)\n")
    }
    
    func scroll(direction: ScrollDirection){
        switch direction{
        case .up:
            anchorPointVel.dy = -CGFloat(1) / scrollingFrameDuration
        case .down:
            anchorPointVel.dy = CGFloat(1) / scrollingFrameDuration
        case .left:
            anchorPointVel.dx = CGFloat(1) / scrollingFrameDuration
        case .right:
            anchorPointVel.dx = -CGFloat(1) / scrollingFrameDuration
        default:
            println("error")
        }
        scrolling = true
        changeSubscene()
    }
    
    func moveAnchor(){
        if (scrollingFrameDuration > 0) && scrolling{
            anchorPoint.x += anchorPointVel.dx
            anchorPoint.y += anchorPointVel.dy
            scrollingFrameDuration--
        }
        else if scrolling {
            anchorPointVel = CGVector(dx: 0, dy: 0)
            anchorPoint = CGPoint(x: CGFloat(-(subscene_index - 1) % subscene_count_horizontal), y: CGFloat(-(subscene_index - 1) / subscene_count_vertical))
            scrolling = false
            scrollingFrameDuration = CGFloat(30)
            scrollDirection = nil
        }
    }
    
    func changeSubscene(){
        switch scrollDirection!{
        case .up:
            subscene_index += 2
        case .down:
            subscene_index -= 2
        case .left:
            subscene_index -= 1
        case .right:
            subscene_index += 1
        default:
            println("error")
        }
    }
    
    func deletePeerBalls(message: MessageDead, peerPlayerID: Int) {
        println("Received delete peer id\(peerPlayerID)")
        opponentsWrapper.deleteOpponentBall(peerPlayerID, message: message)
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        opponentsWrapper.updatePeerPos(peerPlayerID, message: message)
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

    override func className() -> String{
        return "GameScene"
    }
}
