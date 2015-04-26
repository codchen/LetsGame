//
//  GamePoolScene.swift
//  OmniBall
//
//  Created by Fang on 4/21/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class GamePoolScene: GameScene {
    
    var boundRect: CGRect!
    var wave: Int!
    
    override func setupHUD() {
        super.setupHUD()
        let startPos = CGPoint(x: 100, y: size.height - 300)
        for var i = 0; i < slaveNum; ++i {
            let minion = SKSpriteNode(imageNamed: "80x80_star_slot")
            minion.position = startPos + CGPoint(x: CGFloat(i) * (minion.size.width), y: 0)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.addChild(minion)
            collectedMinions.append(false)
        }
    }
    
    override func setupNeutral() {
        enumerateChildNodesWithName("neutral*"){ node, _ in
            let neutralNode = node as SKSpriteNode
            neutralNode.size = CGSize(width: 110, height: 110)
            neutralNode.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "staro"), size: CGSize(width: 110, height: 110))
            neutralNode.physicsBody?.dynamic = false
            neutralNode.physicsBody!.restitution = 1
            neutralNode.physicsBody!.linearDamping = 0
            neutralNode.physicsBody!.categoryBitMask = physicsCategory.target
            neutralNode.physicsBody!.contactTestBitMask = physicsCategory.Me
            self.neutralBalls[neutralNode.name!] = NeutralBall(node: neutralNode, lastCapture: 0)
        }
    }
    
    override func setupDestination(origin: Bool) {
        let topWall = childNodeWithName("barTop") as SKSpriteNode
        let bottomWall = childNodeWithName("barBottom") as SKSpriteNode
        let leftWall = childNodeWithName("barLeft") as SKSpriteNode
        let rightWall = childNodeWithName("barRight") as SKSpriteNode
        boundRect = CGRect(x: leftWall.position.x, y: bottomWall.position.y, width: rightWall.position.x - leftWall.position.x, height: topWall.position.y - bottomWall.position.y)
        debugDrawPlayableArea(boundRect)
    }
    
    func debugDrawPlayableArea(rect: CGRect) {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, rect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
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
    
    override func scored() {
        super.scored()
        self.remainingSlave--
        addHudStars(myNodes.id)
    }
    
    override func checkGameOver() {
        if remainingSlave == 0 {
            gameOver = true
            if connection.me.score == connection.peersInGame.getMaxScore() {
                gameOver(won: true)
            } else {
                gameOver(won: false)
            }
        }
        
    }
    
    override func checkOutOfBound() {
        var deCapList = [SKSpriteNode]()
        for (name, slave) in myNodes.slaves {
            if !CGRectContainsPoint(boundRect, slave.node.position) {
                myNodes.successNodes += 1
                myNodes.score++
                connection.peersInGame.increaseScore(myNodes.id)
                let slaveName = name as NSString
                let index: Int = slaveName.substringFromIndex(7).toInt()!
                deCapList.append(slave.node)
                slave.node.removeFromParent()
                myNodes.sendDead(UInt16(index))
                scored()
                changeDest()
            }
        }
        for deleteNode in deCapList {
            enableSound = false
            myNodes.decapture(deleteNode)
        }
        for var i = 0; i < myNodes.count; ++i {
            if !CGRectContainsPoint(boundRect, myNodes.players[i].position) {
                myNodes.players[i].physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                myNodes.players[i].position = myNodes.bornPos[i]
                connection.sendReborn(UInt16(i))
                anchorPoint = CGPointZero
                hudLayer.position = CGPointZero
            }
        }
        enableSound = true
    }

}
