//
//  GameScene.swift
//  TestForCollision
//
//  Created by Xiaoyu Chen on 2/2/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    let ballSize: CGFloat = 110
    var destPos: CGPoint!
    var neutralPos: CGPoint!
    var destRotation: CGFloat!
    var destHeart: SKShapeNode!
    var destPointer: SKSpriteNode!
    var enableBackgroundMove: Bool = true
    var updateDest: Bool = false
    
    let collisionSound = SKAction.playSoundFileNamed("Electric Hit.mp3", waitForCompletion: false)
    let whatSound = SKAction.playSoundFileNamed("What.mp3", waitForCompletion: false)
    let yeahSound = SKAction.playSoundFileNamed("Yeah.mp3", waitForCompletion: false)
    var enableSound: Bool = true
    
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
	var connection: ConnectionManager!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    let protectionInterval: Double = 2
    var gameOver: Bool = false
    
    //receive capture stuff
    var scheduleToCapture: [SKSpriteNode] = []
    var scheduleCaptureBy: [Player] = []
    var scheduleUpdateTime: [Double] = []
    
    // hud layer stuff
    var hudMinions: [SKSpriteNode] = []
    let hudLayer: SKNode = SKNode()
    var collectedMinions: [Bool] = []

    // special effect
//    var emitterHalo: SKEmitterNode!
	
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
//        for var index = 0; index < slaveNum; ++index {
//            neutralPos.append(CGPointZero)
//        }
        
//        if childNodeWithName("boundary") != nil {
//            let boundary = childNodeWithName("boundary") as SKSpriteNode
//            boundary.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "map"), alphaThreshold: -0.1, size: boundary.size)
//            boundary.physicsBody?.dynamic = false
//        }
        
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
        
        enumerateChildNodesWithName("bar*") { node, _ in
            node.physicsBody!.categoryBitMask = physicsCategory.wall
        }
        
        enumerateChildNodesWithName("wall") { node, _ in
            node.physicsBody!.categoryBitMask = physicsCategory.wall
        }
        
    }
    
    func setupDestination(origin: Bool){
        
    }
    
    func setupHUD(){
        //        scoreLabel.position = CGPoint(x: size.width - 300, y: size.height - 320)
        //        scoreLabel.fontSize = 60
        //        scoreLabel.fontColor = SKColor.whiteColor()
        //        scoreLabel.fontName = "Copperplate"
        //        scoreLabel.text = "score: " + String(myNodes.score)
        //        hudLayer.addChild(scoreLabel)
    }
    
    func setupNeutral(){
    }
    
    // MARK: Gameplay physics
    
    func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        var slaveNode: SKSpriteNode = contact.bodyA.node! as SKSpriteNode
        var hunterNode: SKSpriteNode = contact.bodyB.node! as SKSpriteNode

        if collision == physicsCategory.Me | physicsCategory.target{
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                slaveNode = contact.bodyB.node! as SKSpriteNode
            }
            runAction(collisionSound)
            capture(target: slaveNode, hunter: myNodes)
        } else if collision == physicsCategory.Opponent | physicsCategory.target{
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                slaveNode = contact.bodyB.node! as SKSpriteNode
                hunterNode = contact.bodyA.node! as SKSpriteNode
            }
            var opp = opponentsWrapper.getOpponentByName(hunterNode.name!)
            runAction(collisionSound)
            capture(target: slaveNode, hunter: opp!)
        } else if collision == physicsCategory.Me | physicsCategory.Opponent
        	|| collision == physicsCategory.Me | physicsCategory.wall || collision == physicsCategory.target | physicsCategory.wall{
            runAction(collisionSound)
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
            neutralBalls[target.name!]?.lastCapture = now
            connection.sendNeutralInfo(UInt16(index), id: hunter.id, lastCaptured: now)
        }
    }
    
    func performScheduledCapture(){
        while scheduleToCapture.count > 0{
            //check if already captured
            //println("perform scheduled capture \(scheduleToCapture.count), \(scheduleCaptureBy.count), \(scheduleUpdateTime.count)")
            let name: NSString = scheduleToCapture[0].name! as NSString
            let index: Int = name.substringFromIndex(7).toInt()!
            myNodes.decapture(scheduleToCapture[0])
            opponentsWrapper.decapture(scheduleToCapture[0])
            assert(!scheduleCaptureBy.isEmpty, "ScheduleCaptureBy is not empty")
            scheduleCaptureBy[0].capture(scheduleToCapture[0], capturedTime: scheduleUpdateTime[0])
//            hudMinions[index].texture = scheduleToCapture[0].texture
            neutralBalls[name]?.lastCapture = scheduleUpdateTime[0]
            scheduleToCapture.removeAtIndex(0)
            scheduleCaptureBy.removeAtIndex(0)
            scheduleUpdateTime.removeAtIndex(0)
        }
    }
    
    func scored(){
    }
    
    func addHudStars(id: UInt16) {
    }

	// MARK: Scene rendering cycle
    override func update(currentTime: CFTimeInterval) {
        
        if !gameOver {
            checkGameOver()
        }
        performScheduledCapture()
        myNodes.checkOutOfBound()
        opponentsWrapper.checkDead()
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        myNodes.sendMove()
    }
    
    func update_peer_dead_reckoning(){
        opponentsWrapper.update_peer_dead_reckoning()
    }
    
    func checkGameOver() {
    }
    
    func gameOver(#won: Bool) {

    }
    
    // MARK: Gestures
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {

        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        myNodes.touchesBegan(loc)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if enableBackgroundMove && myNodes.launchPoint == nil {
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
        if anchorPoint.x > 2 {
            anchorPoint.x = 2
        } else if anchorPoint.x < -2 {
            anchorPoint.x = -2
        }
        
        if anchorPoint.y > 2 {
            anchorPoint.y = 2
        } else if anchorPoint.y < -2 {
            anchorPoint.y = -2
        }
        let offset = oldAnchorPoint - anchorPoint
        hudLayer.position += offset * CGPointMake(size.width, size.height)
        
    }

    // MARK: Update from peerMessage
    func deletePeerBalls(message: MessageDead, peerPlayerID: Int) {
        opponentsWrapper.deleteOpponentSlave(peerPlayerID, message: message)
        remainingSlave--
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        opponentsWrapper.updatePeerPos(peerPlayerID, message: message)
    }
    
    func updateReborn(message: MessageReborn, peerPlayerID: Int){
        opponentsWrapper.updateReborn(peerPlayerID, message: message)
    }
    
    func paused(){
    }
    
    func changeDest(){
    }
    
    func updateNeutralInfo(message: MessageNeutralInfo, playerID: Int){
        let pointTo: Player = getPlayerByID(message.id)!
        let neutralName = "neutral" + String(message.index)
        let target = neutralBalls[neutralName]!
        
        if pointTo.slaves[target.node.name!] != nil{
            return
        }
        
        let sentTime = message.lastCaptured - connection.delta[playerID]!
        if sentTime > target.lastCapture + protectionInterval || (sentTime > target.lastCapture - protectionInterval && sentTime < target.lastCapture){
            scheduleToCapture.append(target.node)
            scheduleCaptureBy.append(pointTo)
            scheduleUpdateTime.append(sentTime)	// corrected from message.lastCaptured
        }
    }
    
    func updateDestination(desPos: CGPoint, desRotation: CGFloat, starPos: CGPoint) {
        self.destPos = desPos
        self.destRotation = desRotation
        self.neutralPos = starPos
        updateDest = true
    }
    
    // MARK: Util Code
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
    
    override func className() -> String{
        return "GameScene"
    }
}
