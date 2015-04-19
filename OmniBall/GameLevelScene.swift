//
//  GameLevelScene.swift
//  OmniBall
//
//  Created by Fang on 3/15/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class GameLevelScene: GameScene {
    var destPosList: [CGPoint] = []
    var whichPos = 0
    let btnComeBack = SKSpriteNode(imageNamed: "circle")
    
    override func didMoveToView(view: SKView){
        super.didMoveToView(view)
        enableBackgroundMove = true
        setupDestination(false)
        enumerateChildNodesWithName("destHeart*") {node, _ in
            self.destPosList.append(node.position)
            node.physicsBody = nil
        }
    }
    
    var currentLevel = 0
    
    override func setupDestination(origin: Bool) {
        destPointer = childNodeWithName("destPointer") as! SKSpriteNode
        destPointer.zPosition = -5
        destPointer.physicsBody!.allowsRotation = false
        destPointer.physicsBody!.dynamic = false
        destPointer.physicsBody!.pinned = false
        //destHeart = childNodeWithName("destHeart") as SKShapeNode
        destHeart = SKShapeNode(circleOfRadius: 200)
        destHeart.zPosition = -10
        destHeart.position = destPointer.position
        destPointer.physicsBody?.categoryBitMask = physicsCategory.wall
        addChild(destHeart)
    }
    
    override func setupHUD() {
		super.setupHUD()
        let totalSlaveNum = ((1 + slaveNum) * (_scene2modelAdptr.getMaxLevel() + 1))/2
        let startPos = CGPoint(x: 100, y: size.height - 300)
        for var i = 0; i < totalSlaveNum; ++i {
            let minion = SKSpriteNode(imageNamed: "80x80_star_slot")
            minion.position = startPos + CGPoint(x: CGFloat(i) * (minion.size.width), y: 0)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.addChild(minion)
            collectedMinions.append(false)
        }
                
        for peer in _scene2modelAdptr.getPeers() {
            println("ADD HUD STARS!!" + String(peer.playerID))
            var peerScore: Int = peer.score
            while peerScore > 0 {
                addHudStars(peer.playerID)
                peerScore--
            }
        }
    
        btnComeBack.name = "comeBack"
        btnComeBack.position = CGPoint(x: size.width - 100, y: 300)
        btnComeBack.position = hudLayer.convertPoint(btnComeBack.position, fromNode: self)
        btnComeBack.setScale(1.5)
        hudLayer.addChild(btnComeBack)
    }
    
    override func setupNeutral() {
        enumerateChildNodesWithName("neutral*"){ node, _ in
            let neutralNode = node as! SKSpriteNode
            neutralNode.size = CGSize(width: 110, height: 110)
            neutralNode.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "80x80_orange_star"), size: CGSize(width: 110, height: 110))
            neutralNode.physicsBody?.dynamic = false
            neutralNode.physicsBody!.restitution = 1
            neutralNode.physicsBody!.linearDamping = 0
            neutralNode.physicsBody!.categoryBitMask = physicsCategory.target
            neutralNode.physicsBody!.contactTestBitMask = physicsCategory.Me
            self.neutralBalls[neutralNode.name!] = NeutralBall(node: neutralNode, lastCapture: 0)
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        performScheduledCapture()
        myNodes.checkOutOfBound()
        opponentsWrapper.checkDead()
    }
    
    override func addHudStars(id: UInt16) {
        var startIndex = 0
        let player = getPlayerByID(id)!
        while collectedMinions[startIndex] {
            startIndex++
        }
        collectedMinions[startIndex] = true
        hudMinions[startIndex].texture = SKTexture(imageNamed: getSlaveImageName(player.color, false))

    }
    
    override func checkGameOver() {
        println("CurrentLevel is " + String(currentLevel))
        println("Remaining slave is " + String(remainingSlave))
        if remainingSlave == 0 && currentLevel == _scene2modelAdptr.getMaxLevel() {
            var maxScore: Int = _scene2modelAdptr.getMaxScore()
            println("in checking game over")
            if maxScore == _scene2modelAdptr.getScore(playerID: myNodes.id) {
                gameOver = true
                _scene2modelAdptr.sendGameOver()
                println("Game Over?")
                gameOver(won: true)
            }
        }
    }
    
    override func scored() {
        addHudStars(myNodes.id)
        self.remainingSlave--
        runAction(scoredSound)
        println(remainingSlave)
        if remainingSlave == 0 {
            checkGameOver()
            if (gameOver == false && _scene2controllerAdptr.getCurrentLevel() < _scene2modelAdptr.getMaxLevel()){
                _scene2modelAdptr.sendPause()
                paused()
            }
        }
    }
    
    override func paused(){
        player.stop()
        physicsWorld.speed = 0
        currentLevel++
        let levelScene = LevelXScene(size: self.size, level: currentLevel)
        levelScene.scaleMode = self.scaleMode
        levelScene._scene2controllerAdptr = _scene2controllerAdptr
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(levelScene, transition: reveal)
        
    }
    
    override func changeDest(){
        whichPos++
        destPointer.position = destPosList[whichPos % destPosList.count]
        destHeart.position = destPosList[whichPos % destPosList.count]
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            let loc = touch.locationInNode(self)
            myNodes.touchesBegan(loc)
            if btnComeBack.containsPoint(hudLayer.convertPoint(loc, fromNode: self)) {
                println("pressed button")
                anchorPoint = CGPoint(x: -myNodes.players[0].position.x/size.width + 0.5,
                    y: -myNodes.players[0].position.y/size.height + 0.5)
                hudLayer.position = CGPoint(x: -anchorPoint.x * size.width, y: -anchorPoint.y * size.height)
            }
        }
    }
}
