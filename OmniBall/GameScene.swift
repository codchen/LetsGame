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
    var maxSucessNodes = 5
    var slaveNum: Int = 1
    var remainingSlave: Int = 1
    
    //let bound: CGFloat = 2733
    var scrolling = false
    
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
    var collectedMinions: [Bool] = []

	
    // MARK: Game Scene Setup
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
//            debugDrawPlayableArea()

        }
        neutral.position = neutralPos
        destPointer.position = destPos
        destPointer.zRotation = destRotation
        destHeart.position = destPos
    }
    
    func setupHUD(){
        let tempAnchor = anchorPoint
        hudLayer.position = CGPoint(x: -tempAnchor.x * size.width, y: -tempAnchor.x * size.height)
        hudLayer.zPosition = 5
        addChild(hudLayer)
        
        
        for var i = 0; i < connection.maxPlayer; ++i {
            var startPos: CGPoint!
            if i == 0 {
                startPos = CGPoint(x: 100, y: size.height - 300)
            } else if i == 1 {
                startPos = CGPoint(x: size.width/2 - 250, y: size.height - 300)
            } else if i == 2 {
                startPos = CGPoint(x: size.width - 500, y: size.height - 300)
            }
            for var index = 0; index < 5; ++index {
                let minion = SKSpriteNode(imageNamed: "80x80_star_slot")
                minion.position = startPos + CGPoint(x: CGFloat(index) * (minion.size.width), y: 0)
                //                minion.position = CGPoint(x: 100 + CGFloat(index) * (minion.size.width + 10), y: size.height - 300)
                minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
                hudMinions.append(minion)
                hudLayer.addChild(minion)
                collectedMinions.append(false)
            }
        }
        
        for (id, var score) in connection.scoreBoard {
            while score > 0 {
                addHudStars(UInt16(id))
                score--
            }
        }
        
        //        scoreLabel.position = CGPoint(x: size.width - 300, y: size.height - 320)
        //        scoreLabel.fontSize = 60
        //        scoreLabel.fontColor = SKColor.whiteColor()
        //        scoreLabel.fontName = "Copperplate"
        //        scoreLabel.text = "score: " + String(myNodes.score)
        //        hudLayer.addChild(scoreLabel)
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
    
    // Generate random position for neutral stars
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
    
    // Generate random position for destination node
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
    
    // Check whether the generated position is valid: AKA. no stars/balls in it
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
            if nodeToCheck.intersectsNode(node) {
                isValid = false
            }
        }
        return isValid
    }
    
	// MARK: Debugging code
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, destRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
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
            
//            hudMinions[index].texture = target.texture
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
            scheduleCaptureBy[0].capture(scheduleToCapture[0], capturedTime: scheduleUpdateTime[0])
//            hudMinions[index].texture = scheduleToCapture[0].texture
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
    }
    
    func scored(){
        addHudStars(myNodes.id)
        connection.sendPause()
        paused()
        remainingSlave--
        setupNeutral()
        setupDestination(true)
        readyGo()
    }
    
    func addHudStars(id: UInt16) {
        let player = getPlayerByID(id)!
        var startIndex = 0
        
        if player.color == PlayerColors.Green {
            startIndex = 0
        } else if player.color == PlayerColors.Red {
            startIndex = 5
        } else {
            startIndex = 10
        }
        
        while collectedMinions[startIndex] {
            startIndex++
        }
        collectedMinions[startIndex] = true
        hudMinions[startIndex].texture = SKTexture(imageNamed: getSlaveImageName(player.color, false))
    }

	// MARK: Scene rendering cycle
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
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        myNodes.sendMove()
    }
    
    // MARK: Gestures
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
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        myNodes.touchesEnded(loc)
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


    
    func deletePeerBalls(message: MessageDead, peerPlayerID: Int) {
        opponentsWrapper.deleteOpponentSlave(peerPlayerID, message: message)
        remainingSlave--
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        opponentsWrapper.updatePeerPos(peerPlayerID, message: message)
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
