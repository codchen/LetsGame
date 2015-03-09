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
    let bound: CGFloat = 2733
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
    var neutralBalls: Dictionary<String, NeutralBall> = Dictionary<String, NeutralBall>()
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    let protectionInterval: Double = 1
//    var lastCaptured: [Double] = [0, 0, 0, 0]
    
    var gameOver: Bool = false
    
    //receive capture stuff
    var scheduleToCapture: [SKSpriteNode] = []
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
        hudLayer.position = CGPoint(x: -tempAnchor.x * size.width, y: -tempAnchor.x * size.height)
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
            self.neutralBalls[node1.name!] = NeutralBall(node: node1, lastCapture: 0)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        var slaveNode: SKSpriteNode = contact.bodyA.node! as SKSpriteNode
        var hunterNode: SKSpriteNode = contact.bodyB.node! as SKSpriteNode

        if collision == physicsCategory.Me | physicsCategory.target{
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                slaveNode = contact.bodyB.node! as SKSpriteNode
            }
            capture(target: slaveNode, hunter: myNodes)
        } else if collision == physicsCategory.Opponent | physicsCategory.target{
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                slaveNode = contact.bodyB.node! as SKSpriteNode
                hunterNode = contact.bodyA.node! as SKSpriteNode
            }
            var opp = opponentsWrapper.getOpponentByName(hunterNode.name!)
            capture(target: slaveNode, hunter: opp!)
        }
    }
    
    func capture(#target: SKSpriteNode, hunter: Player) {

        let now = NSDate().timeIntervalSince1970
        let name: NSString = target.name! as NSString
        let index: Int = name.substringFromIndex(7).toInt()!
        let targetInfo = neutralBalls[target.name!]!

        if (now >= targetInfo.lastCapture + protectionInterval ||
            (now > targetInfo.lastCapture - protectionInterval &&
                now < targetInfo.lastCapture))&&(hunter.slaves[target.name!] == nil){

            opponentsWrapper.decapture(target)
            myNodes.decapture(target)
            println("Hunter \(hunter.sprite) captured \(target.name!)")
            assert(hunter.slaves[target.name!] == nil, "hunter is not nil before capture")
            hunter.capture(target, capturedTime: now)
            assert(hunter.slaves[target.name!] != nil, "Hunter didn't captured \(target.name!)")
            
            hudMinions[index].texture = target.texture
            neutralBalls[target.name!]?.lastCapture = now
            connection.sendNeutralInfo(UInt16(index), id: hunter.id, lastCaptured: now)
        }
    }
    
    func updateNeutralInfo(message: MessageNeutralInfo, playerID: Int){
        let pointTo: Player = getPlayerByID(message.id)!
        let neutralName = "neutral" + String(message.index)
        let target = neutralBalls[neutralName]!

        if pointTo.slaves[target.node.name!] != nil{
            return
        }
        
        let sentTime = message.lastCaptured + connection.delta[playerID]!
        if sentTime > target.lastCapture + protectionInterval || (sentTime > target.lastCapture - protectionInterval && sentTime < target.lastCapture){
            scheduleToCapture.append(target.node)
            scheduleCaptureBy.append(pointTo)
            scheduleUpdateTime.append(sentTime)	// corrected from message.lastCaptured
        }
    }
    
    func getPlayerByID(id: UInt16) -> Player?{
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
            let name: NSString = scheduleToCapture[0].name! as NSString
            let index: Int = name.substringFromIndex(7).toInt()!
            myNodes.decapture(scheduleToCapture[0])
            opponentsWrapper.decapture(scheduleToCapture[0])
//            let target = childNodeWithName("neutral\(scheduleToCapture[0])") as SKSpriteNode
            scheduleCaptureBy[0].capture(scheduleToCapture[0], capturedTime: scheduleUpdateTime[0])
            println("From Message Hunter \(scheduleCaptureBy[0].sprite) captured \(scheduleToCapture[0].name!)")
            println("From Message, time is \(scheduleUpdateTime[0])")
            hudMinions[index].texture = scheduleToCapture[0].texture
            neutralBalls[name]?.lastCapture = scheduleUpdateTime[0]
            scheduleToCapture.removeAtIndex(0)
            scheduleCaptureBy.removeAtIndex(0)
            scheduleUpdateTime.removeAtIndex(0)
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
        myNodes.checkOutOfBound()
        opponentsWrapper.checkDead()
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
        
        myNodes.touchesBegan(loc)
        setSrollDirection(loc)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let currentLocation = touch.locationInNode(self)
        let previousLocation = touch.previousLocationInNode(self)
        if myNodes.launchPoint == nil {
            let translation = currentLocation - previousLocation
            // move anchorPoint
            anchorPoint += translation/CGPointMake(size.width, size.height)
            // move hudLayer
            hudLayer.position -= translation
            checkBackgroundBond()
        }
        
    }
    
    func checkBackgroundBond() {
        
        let oldAnchorPoint = anchorPoint
        if anchorPoint.x > 1 {
            anchorPoint.x = 1
        } else if anchorPoint.x < -1 {
            anchorPoint.x = -1
        }
        
        if anchorPoint.y > 1 {
            anchorPoint.y = 1
        } else if anchorPoint.y < -1 {
            anchorPoint.y = -1
        }
        let offset = oldAnchorPoint - anchorPoint
        hudLayer.position += offset * CGPointMake(size.width, size.height)
        
    }

    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        myNodes.touchesEnded(loc)
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
        opponentsWrapper.deleteOpponentSlave(peerPlayerID, message: message)
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
