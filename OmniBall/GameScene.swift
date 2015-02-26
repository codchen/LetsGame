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
    case Green = 0, Red, Blue, Yellow
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
    var scrollLaunchPoint: CGPoint!
    
    let initial_subscene_index = 12
    var subscene_index = 12
    let subscene_count_horizontal = 5
    let subscene_count_vertical = 5
    
    // Opponents Setting
    var myNodes: MyNodes!
    var opponentsWrapper: OpponentsWrapper!
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    let protectionInterval: Double = 1
    var lastCaptured: [Double] = [0, 0, 0, 0]
    
    var gameOver: Bool = false
    
    //receive capture stuff
    var scheduleToCapture: [Int] = []
    var scheduleCaptureBy: [Player] = []
    var scheduleUpdateTime: [Double] = []
    
    // hud layer stuff
    var hudMinions: [SKSpriteNode] = []
    let hudLayer: SKNode = SKNode()
    let slaveNum = 4
    
    override func didMoveToView(view: SKView) {
        
        size = CGSize(width: 2048, height: 1536)
        
        setupHUD()
        connection.gameState = .InGame
        myNodes = MyNodes(connection: connection, scene: self)
        opponentsWrapper = OpponentsWrapper()
        setupNeutral()
        for var index = 0; index < connection.maxPlayer; ++index {
            if Int(connection.playerID) != index {
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
    
    func setupHUD(){
		let tempAnchor = getAnchorPoint()
        println(tempAnchor)
        hudLayer.position = CGPoint(x: -tempAnchor.x * size.width, y: -tempAnchor.x * size.height)
        println("HudLayer Pos \(hudLayer.position)")
        hudLayer.zPosition = 5
        addChild(hudLayer)
        
        for var index = 0; index < slaveNum; ++index {
            let minion = SKSpriteNode(imageNamed: "circle")
            minion.position = CGPoint(x: 100 + CGFloat(index) * (minion.size.width + 25), y: size.height - 300)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.addChild(minion)
        }
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
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == physicsCategory.Me | physicsCategory.target{
            let now = NSDate().timeIntervalSince1970
            var node: SKSpriteNode = contact.bodyA.node! as SKSpriteNode
            println(node.name)
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                node = contact.bodyB.node! as SKSpriteNode
                println(node.name)
            }
            println("Collision body A: \(contact.bodyA.node?.name)")
            println("Collision body B: \(contact.bodyB.node?.name)")
            println("Collision is \(collision)")
            println(node.name)
            let name: NSString = node.name! as NSString
            let index: Int = name.substringFromIndex(7).toInt()!
            println("Last Capture is \(lastCaptured[index])")
            println("Sent Capture is \(now)")
            if (now >= lastCaptured[index] + protectionInterval || (now > lastCaptured[index] - protectionInterval && now < lastCaptured[index]))&&(myNodes.capturedIndex[index] == -1){
                opponentsWrapper.decapture(index)
                myNodes.capture(index, target: node)
                hudMinions[index].texture = node.texture
                lastCaptured[index] = now
                //connection.sendCaptured(UInt16(index), time: now, count: myNodes.msgCount)
                connection.sendNeutralInfo(UInt16(index), id: myNodes.id, lastCaptured: now)
            }
            
        }
        else if collision == physicsCategory.Opponent | physicsCategory.target{
            let now = NSDate().timeIntervalSince1970
            var node: SKSpriteNode = contact.bodyA.node! as SKSpriteNode
            var toucher: SKSpriteNode = contact.bodyB.node! as SKSpriteNode
            println(node.name)
            println(toucher.name)
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                node = contact.bodyB.node! as SKSpriteNode
                toucher = contact.bodyA.node! as SKSpriteNode
                println(node.name)
                println(toucher.name)
            }
            var opp: OpponentNodes!
            for (peer, opponent) in opponentsWrapper.opponents{
                if opponent.sprite == toucher.name{
                    opp = opponent
                    break
                }
            }
            println(node.name)
            println(toucher.name)
            let name: NSString = node.name! as NSString
            let index: Int = name.substringFromIndex(7).toInt()!
            if (now >= lastCaptured[index] + protectionInterval || (now > lastCaptured[index] - protectionInterval && now < lastCaptured[index]))&&(opp.capturedIndex[index] == -1){
                myNodes.decapture(index)
                opponentsWrapper.decapture(index)
                opp.capture(index, target: node)
                hudMinions[index].texture = node.texture
                lastCaptured[index] = now
                //connection.sendCaptured(UInt16(index), time: now, count: myNodes.msgCount)
                connection.sendNeutralInfo(UInt16(index), id: opp.id, lastCaptured: now)
            }
        }
    }
    
    func updateCaptured(message: MessageCapture, playerID: Int){
        println("updateCaptured")
        println("LastCaptured:")
        for i in lastCaptured{
            println(i)
        }
        println("Receive Captured \(Int(message.index)) at time \(message.time) from peer \(playerID)")
        println("Last Capture is \(lastCaptured[Int(message.index)])")
        if message.time >= lastCaptured[Int(message.index)] + protectionInterval ||
        	message.time < lastCaptured[Int(message.index)] {
            myNodes.updateCaptured(message)
            opponentsWrapper.updateCaptured(playerID, message: message)
            lastCaptured[Int(message.index)] = message.time
        } else {
            println("Protecting")
        }
    }
    
    func updateNeutralInfo(message: MessageNeutralInfo, playerID: Int){
        let pointTo: Player = getByID(message.id)!
        let index = (Int)(message.index)
        if pointTo.capturedIndex[index] != -1{
            return
        }
        let sentTime = message.lastCaptured + connection.delta[playerID]!
        if sentTime > lastCaptured[index] + protectionInterval || (sentTime > lastCaptured[index] - protectionInterval && sentTime < lastCaptured[index]){
            scheduleToCapture.append(index)
            scheduleCaptureBy.append(pointTo)
            scheduleUpdateTime.append(message.lastCaptured)
        }
        
    }
    
    func getByID(id: UInt16) -> Player?{
        if myNodes.id == id{
            return myNodes
        }
        else{
            for (peer, oppo) in opponentsWrapper.opponents{
                if oppo.id == id{
                    return oppo
                }
            }
        }
        println("invalid id")
        return nil
    }
    
    func performScheduledCapture(){
        while scheduleToCapture.count > 0{
            //check if already captured
            myNodes.decapture(scheduleToCapture[0])
            opponentsWrapper.decapture(scheduleToCapture[0])
            let target = childNodeWithName("neutral\(scheduleToCapture[0])") as SKSpriteNode
            scheduleCaptureBy[0].capture(scheduleToCapture[0], target: target)
            hudMinions[scheduleToCapture[0]].texture = target.texture
            lastCaptured[scheduleToCapture[0]] = scheduleUpdateTime[0]
            scheduleToCapture.removeAtIndex(0)
            scheduleCaptureBy.removeAtIndex(0)
            scheduleUpdateTime.removeAtIndex(0)
        }
    }
    
    func broadcastNeutral(){
        for var i = 0; i < lastCaptured.count; ++i{
            var id: UInt16!
            if myNodes.capturedIndex[i] != -1{
                id = myNodes.id
                connection.sendNeutralInfo(UInt16(i), id: id, lastCaptured: lastCaptured[i])
            }
            else{
                for (peer, oppo) in opponentsWrapper.opponents{
                    if oppo.capturedIndex[i] != -1{
                        id = oppo.id
                        connection.sendNeutralInfo(UInt16(i), id: id, lastCaptured: lastCaptured[i])
                        break
                    }
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
        
        performScheduledCapture()
        //myNodes.checkDead()
        //opponentsWrapper.checkDead()
        myNodes.checkOutOfBound()
        moveAnchor()
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        //broadcastNeutral()
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
                if (loc.y < -anchorPoint.y * size.height + size.height - 500) && subscene_index / subscene_count_horizontal != subscene_count_vertical - 1{
                    scroll(scrollDirection)
                }
            case .down:
                if (loc.y > -anchorPoint.y * size.height + 500) && subscene_index / subscene_count_horizontal != 0 {
                    scroll(scrollDirection)
                }
            case .left:
                if (loc.x > -anchorPoint.x * size.width + 500) && subscene_index % subscene_count_horizontal != 0 {
                    scroll(scrollDirection)
                }
            case .right:
                if (loc.x < -anchorPoint.x * size.width + size.width - 500) && subscene_index % subscene_count_horizontal != subscene_count_horizontal - 1 {
                    scroll(scrollDirection)
                }
            default:
                println("error scrolling")
            }
            
        }
    }
    
    func setSrollDirection(location: CGPoint) {
        if location.y > (-anchorPoint.y * size.height + size.height - 300){
            scrollDirection = .up
        }
        else if location.y < (-anchorPoint.y * size.height + 300){
            scrollDirection = .down
        }
        else if location.x < (-anchorPoint.x * size.width + 300){
            scrollDirection = .left
        }
        else if location.x > (-anchorPoint.x * size.width + size.width - 300){
            scrollDirection = .right
        }
    }
    
    func scroll(direction: ScrollDirection){
        switch direction{
        case .up:
            anchorPointVel.dy = -CGFloat(0.5) / scrollingFrameDuration
        case .down:
            anchorPointVel.dy = CGFloat(0.5) / scrollingFrameDuration
        case .left:
            anchorPointVel.dx = CGFloat(0.5) / scrollingFrameDuration
        case .right:
            anchorPointVel.dx = -CGFloat(0.5) / scrollingFrameDuration
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
            hudLayer.position.x += -anchorPointVel.dx * size.width
            hudLayer.position.y += -anchorPointVel.dy * size.height
            scrollingFrameDuration--
        }
        else if scrolling {
            anchorPointVel = CGVector(dx: 0, dy: 0)
            anchorPoint = getAnchorPoint()
            scrolling = false
            scrollingFrameDuration = CGFloat(30)
            scrollDirection = nil
        }
    }
    
    func getAnchorPoint() -> CGPoint{
        let subscene_offset = CGPoint(x: initial_subscene_index % subscene_count_horizontal, y: initial_subscene_index / subscene_count_horizontal)
        return CGPoint(x: 0.5 * CGFloat(Int(subscene_offset.x) - subscene_index % subscene_count_horizontal), y: 0.5 * CGFloat(Int(subscene_offset.y) - subscene_index / subscene_count_horizontal))
    }
    
    func changeSubscene(){
        switch scrollDirection!{
        case .up:
            subscene_index += subscene_count_horizontal
        case .down:
            subscene_index -= subscene_count_horizontal
        case .left:
            subscene_index -= 1
        case .right:
            subscene_index += 1
        default:
            println("error")
        }
    }
    
    func deletePeerBalls(message: MessageDead, peerPlayerID: Int) {
        opponentsWrapper.deleteOpponentBall(peerPlayerID, message: message)
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        opponentsWrapper.updatePeerPos(peerPlayerID, message: message)
    }
    
    func checkGameOver() {
        if myNodes.successNodes == 2 {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: true)
        }
    }
    
    func gameOver(#won: Bool) {
        connection.gameOver()
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
