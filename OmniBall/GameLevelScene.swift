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
    
    let maxLevel: Int = 2
    
    override func setupDestination(origin: Bool) {
        destPointer = childNodeWithName("destPointer") as SKSpriteNode
        destPointer.zPosition = -5
        destPointer.physicsBody!.allowsRotation = false
        destPointer.physicsBody!.dynamic = false
        destPointer.physicsBody!.pinned = false
        destHeart = childNodeWithName("destHeart") as SKShapeNode
        destHeart = SKShapeNode(circleOfRadius: 200)
        destHeart.zPosition = -10
        destHeart.position = destPointer.position
        addChild(destHeart)
    }
    
    override func setupNeutral() {
        enumerateChildNodesWithName("neutral*"){ node, _ in
            let neutralNode = node as SKSpriteNode
            neutralNode.size = CGSize(width: 110, height: 110)
            neutralNode.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "80x80_orange_star"), size: CGSize(width: 110, height: 110))
            neutralNode.physicsBody!.restitution = 1
            neutralNode.physicsBody!.linearDamping = 0
            neutralNode.physicsBody!.categoryBitMask = physicsCategory.target
            neutralNode.physicsBody!.contactTestBitMask = physicsCategory.Me
            self.neutralBalls[neutralNode.name!] = NeutralBall(node: neutralNode, lastCapture: 0)
        }
    }
    
    override func checkGameOver() {
        var scoreToWin = (Float((1 + slaveNum) * maxLevel) * 0.5 + 1) / 2
        if remainingSlave == 0 && Float(myNodes.score) >= scoreToWin {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: true)
        }
    }
    
    override func scored() {
        self.remainingSlave--
        addHudStars(myNodes.id)
        if remainingSlave == 0 {
            checkGameOver()
            println("\(connection.controller.currentLevel)")
            if (gameOver == false && connection.controller.currentLevel < maxLevel - 1){
                connection.sendPause()
                paused()
            }
        }
    }
    
    override func paused(){
        physicsWorld.speed = 0
        currentLevel++
        let levelScene = LevelXScene(size: self.size, level: currentLevel)
        levelScene.scaleMode = self.scaleMode
        levelScene.controller = connection.controller
        levelScene.connection = connection
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(levelScene, transition: reveal)
    }
}
