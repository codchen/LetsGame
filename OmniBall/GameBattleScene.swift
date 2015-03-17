//
//  GameBattleScene.swift
//  OmniBall
//
//  Created by Fang on 3/16/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class GameBattleScene: GameScene {
    
    var destRect: CGRect!
    var destHeart: SKShapeNode!

    
    override func setupDestination(origin: Bool){
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
    
    override func setupHUD() {
        let tempAnchor = anchorPoint
        hudLayer.position = CGPoint(x: -tempAnchor.x * size.width, y: -tempAnchor.x * size.height)
        hudLayer.zPosition = 5
        addChild(hudLayer)
        
        let totalSlaveNum = ((1 + slaveNum) * connection.maxLevel)/2
        let startPos = CGPoint(x: 100, y: size.height - 300)
        for var i = 0; i < totalSlaveNum; ++i {
            let minion = SKSpriteNode(imageNamed: "80x80_star_slot")
            minion.position = startPos + CGPoint(x: CGFloat(i) * (minion.size.width), y: 0)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.addChild(minion)
            collectedMinions.append(false)
        }
    }
    
    override func setupNeutral() {
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
    
    override func addHudStars(id: UInt16) {
        var startIndex = 0
        let player = getPlayerByID(id)!
        while collectedMinions[startIndex] {
            startIndex++
        }
        collectedMinions[startIndex] = true
        hudMinions[startIndex].texture = SKTexture(imageNamed: getSlaveImageName(player.color, false))
    }
    
    override func paused(){
    	physicsWorld.speed = 0
    }
    
    override func scored() {
        addHudStars(myNodes.id)
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
    
    override func checkGameOver(){
        if myNodes.successNodes == self.maxSucessNodes {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: true)
        }
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
}
