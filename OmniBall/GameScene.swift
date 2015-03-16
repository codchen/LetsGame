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
    var destRect: CGRect!
    let ballSize: CGFloat = 110
    var destPos: CGPoint!
    var neutralPos: CGPoint!
    var destRotation: CGFloat!
    var destPointer: SKSpriteNode!
    var destHeart: SKShapeNode!
    var enableBackgroundMove: Bool = true
    var updateDest: Bool = false
    
    // Game Play
    let maxSucessNodes = 5
    var slaveNum: Int = 1
    var remainingSlave: Int = 1
    
    //let bound: CGFloat = 2733
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
    
    var currentLevel = 0
    var gameOver: Bool = false
    
    //receive capture stuff
    var scheduleToCapture: [SKSpriteNode] = []
    var scheduleCaptureBy: [Player] = []
    var scheduleUpdateTime: [Double] = []
    
    // hud layer stuff
    var hudMinions: [SKSpriteNode] = []
    let hudLayer: SKNode = SKNode()
    let scoreLabel: SKLabelNode = SKLabelNode()

    
    override func didMoveToView(view: SKView) {
        
        size = CGSize(width: 2048, height: 1536)
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        
        remainingSlave = slaveNum
        connection.gameState = .InGame
        myNodes = MyNodes(connection: connection, scene: self)
        opponentsWrapper = OpponentsWrapper()
        for var index = 0; index < connection.maxPlayer; ++index {
            if Int(connection.playerID) != index {
                let opponent = OpponentNodes(id: UInt16(index), scene: self)
                opponentsWrapper.addOpponent(opponent)
            }
        }
        setupNeutral()
        if connection.gameMode == GameMode.BattleArena {
            enableBackgroundMove = false
        } else {
            enableBackgroundMove = true
        }
        
        
        if (connection.playerID == 0){
            setupDestination(true)
        }
        else {
            setupDestination(false)
        }
        
        setupHUD()
        
        /* Setup your scene here */

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }
    
    func setupDestination(origin: Bool){
        
        destPointer = childNodeWithName("destPointer") as SKSpriteNode
        destPointer.zPosition = -5
        destPointer.physicsBody!.allowsRotation = false
        destPointer.physicsBody!.dynamic = false
        destPointer.physicsBody!.pinned = false
        destHeart = childNodeWithName("destHeart") as SKShapeNode
        destHeart = SKShapeNode(circleOfRadius: 200)
        destHeart.zPosition = -10
        let neutral = childNodeWithName("neutral0") as SKSpriteNode
        
        if origin {
            let topWall = childNodeWithName("barTop") as SKSpriteNode
            let bottomWall = childNodeWithName("barBottom") as SKSpriteNode
            let leftWall = childNodeWithName("barLeft") as SKSpriteNode
            let rightWall = childNodeWithName("barRight") as SKSpriteNode
            neutralPos = randomPos()
            destRect = CGRectMake(leftWall.position.x + ballSize + 0.5 * destPointer.size.width,
                bottomWall.position.y + ballSize + 0.5 * destPointer.size.height,
                rightWall.position.x - 2 * ballSize - destPointer.size.width - 5,
                topWall.position.y - 2 * ballSize - destPointer.size.height - 5 - bottomWall.position.y)
            destPos = randomDesPos()
            destRotation = CGFloat.random() * π * CGFloat.randomSign()
            connection.sendDestinationPos(Float(destPos.x), y: Float(destPos.y), rotate: Float(destRotation), starX: Float(neutralPos.x), starY: Float(neutralPos.y))
            println(destRect)
            println(destPointer.size)
            debugDrawPlayableArea()

        }
        neutral.position = neutralPos
        destPointer.position = destPos
        destPointer.zRotation = destRotation
        destHeart.position = destPos
        enumerateChildNodesWithName("neutral*"){ node, _ in
        	println("\(node.name) is at \(node.position)")
        }
        
        println("neutralBall at \(neutral.position)")
        
    }
    
    func randomDesPos() -> CGPoint {
        
        var pos = CGPointMake(
            CGFloat.random(min: CGRectGetMinX(destRect), max: CGRectGetMaxX(destRect)),
            CGFloat.random(min: CGRectGetMinY(destRect), max: CGRectGetMaxY(destRect)))
        destHeart.position = pos
        
        while !checkPosValid(destHeart, isNeutral: false) {
            pos = CGPointMake(
                CGFloat.random(min: CGRectGetMinX(destRect), max: CGRectGetMaxX(destRect)),
                CGFloat.random(min: CGRectGetMinY(destRect), max: CGRectGetMaxY(destRect)))
            destHeart.position = pos
        }
        
        return pos
    }
    
    func checkPosValid(nodeToCheck: SKNode, isNeutral: Bool) -> Bool {
        
        var isValid = true
        enumerateChildNodesWithName("node*"){ node, _ in
            if nodeToCheck.intersectsNode(node) {
                isValid = false
            }
        }
        
        if !isValid || (isValid && isNeutral){
            return isValid
        }
        
        enumerateChildNodesWithName("neutral*"){ node, _ in
            println("CHECK CHECK \(node.name)")
            if nodeToCheck.intersectsNode(node) {
                println("Should be invalid")
                isValid = false
            }
        }
        return isValid
    }
    
    func randomPos() -> CGPoint{
        var result: CGPoint = CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 400, max: size.height - 2 * margin - 500))
        
        let neutral = childNodeWithName("neutral0")!
        neutral.position = result
        
        while !checkPosValid(neutral, isNeutral: true) {
            result = CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 400, max: size.height - 2 * margin - 500))
            neutral.position = result
        }
        return result
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, destRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func setupHUD(){
		let tempAnchor = getAnchorPoint()
        hudLayer.position = CGPoint(x: -tempAnchor.x * size.width, y: -tempAnchor.x * size.height)
        hudLayer.zPosition = 5
        addChild(hudLayer)
        
        for var index = 0; index < slaveNum; ++index {
            let minion = SKSpriteNode(imageNamed: "80x80_orange_star")
            minion.position = CGPoint(x: 100 + CGFloat(index) * (minion.size.width + 25), y: size.height - 300)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.addChild(minion)
        }
        
        scoreLabel.position = CGPoint(x: size.width - 300, y: size.height - 320)
        scoreLabel.fontSize = 60
        scoreLabel.fontColor = SKColor.whiteColor()
        scoreLabel.fontName = "Copperplate"
        scoreLabel.text = "score: " + String(myNodes.score)
        hudLayer.addChild(scoreLabel)
    }
    
    func setupNeutral(){
        for var i = 0; i < slaveNum; ++i{
            var node = SKSpriteNode(imageNamed: "80x80_orange_star")
            node.size = CGSize(width: 110, height: 110)
            node.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "80x80_orange_star"), size: CGSize(width: 110, height: 110))
            node.name = "neutral" + String(i)
            node.physicsBody!.restitution = 1
            node.physicsBody!.linearDamping = 0
            node.physicsBody!.categoryBitMask = physicsCategory.target
            node.physicsBody!.contactTestBitMask = physicsCategory.Me
            addChild(node)
            neutralBalls[node.name!] = NeutralBall(node: node, lastCapture: 0)
        }
    }
    
    func updateDestination(desPos: CGPoint, desRotation: CGFloat, starPos: CGPoint) {
        self.destPos = desPos
        self.destRotation = desRotation
        self.neutralPos = starPos
        updateDest = true
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
            hudMinions[index].texture = scheduleToCapture[0].texture
            neutralBalls[name]?.lastCapture = scheduleUpdateTime[0]
            scheduleToCapture.removeAtIndex(0)
            scheduleCaptureBy.removeAtIndex(0)
            scheduleUpdateTime.removeAtIndex(0)
        }
    }
    
    func update_peer_dead_reckoning(){
		opponentsWrapper.update_peer_dead_reckoning()
    }
    
    func paused(){
        physicsWorld.speed = 0
    }
    
    func readyGo(){
        var label = SKSpriteNode(imageNamed: "400x200_ready")
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        addChild(label)
        let action1 = SKAction.scaleTo(4, duration: 0.7)
        let block1 = SKAction.runBlock{
            label.texture = SKTexture(imageNamed: "400x200_go")
            self.physicsWorld.speed = 1
        }
        let action2 = SKAction.waitForDuration(0.5)
        let block2 = SKAction.runBlock{
            label.removeFromParent()
        }
        label.runAction(SKAction.sequence([action1, block1, action2, block2]))
        
//        let ready = SKSpriteNode(imageNamed: "400x200_ready")
//        ready.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        ready.name = "ready"
//        let go = SKSpriteNode(imageNamed: "400x200_go")
//        go.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        go.setScale(4)
//        let block1 = SKAction.runBlock{
//            self.addChild(ready)
//        }
//        let action1 = SKAction.runBlock{
//            ready.runAction(SKAction.scaleTo(4, duration: 1))
//        }
//        let block2 = SKAction.runBlock{
//            ready.removeFromParent()
//            self.addChild(go)
//            self.physicsWorld.speed = 1
//        }
//        let action2 = SKAction.waitForDuration(0.5)
//        let block3 = SKAction.runBlock{
//            go.removeFromParent()
//        }
//        runAction(SKAction.sequence([block1, action1]))
    }
    
    func scored(){
        connection.sendPause()
        paused()
        remainingSlave--
        setupNeutral()
        setupDestination(true)
        readyGo()
    }

    override func update(currentTime: CFTimeInterval) {
        
        if !gameOver {
            checkGameOver()
        }
        
        performScheduledCapture()
        myNodes.checkOutOfBound()
        opponentsWrapper.checkDead()
        if updateDest {
            setupNeutral()
            setupDestination(false)
            updateDest = false
            readyGo()
        }
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
        
        myNodes.touchesBegan(loc)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if enableBackgroundMove {
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
        remainingSlave--
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        opponentsWrapper.updatePeerPos(peerPlayerID, message: message)
    }
    
    func updateScore(){
        scoreLabel.text = "score: " + String(myNodes.score)
    }
    
    func checkGameOver() {
        if myNodes.successNodes == self.maxSucessNodes {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: true)
        }
    }
    
    func gameOver(#won: Bool) {
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.currentLevel = currentLevel        
        gameOverScene.scaleMode = scaleMode
        gameOverScene.controller = connection.controller
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }

    override func className() -> String{
        return "GameScene"
    }
}
