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
    
    override func didMoveToView(view: SKView){
        super.didMoveToView(view)
        enumerateChildNodesWithName("destHeart*") {node, _ in
            self.destPosList.append(node.position)
        }
        println("\(destPosList.count)")
    }
    
    var currentLevel = 0
    
    override func setupDestination(origin: Bool) {
        destPointer = childNodeWithName("destPointer") as SKSpriteNode
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
        
        let tempAnchor = anchorPoint
        hudLayer.position = CGPoint(x: -tempAnchor.x * size.width, y: -tempAnchor.x * size.height)
        hudLayer.zPosition = 5
        addChild(hudLayer)
        
        let totalSlaveNum = ((1 + slaveNum) * (connection.maxLevel + 1))/2
        let startPos = CGPoint(x: 100, y: size.height - 300)
        for var i = 0; i < totalSlaveNum; ++i {
            let minion = SKSpriteNode(imageNamed: "80x80_star_slot")
            minion.position = startPos + CGPoint(x: CGFloat(i) * (minion.size.width), y: 0)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.addChild(minion)
            collectedMinions.append(false)
        }
                
        for (id, var score) in connection.scoreBoard {
            while score > 0 {
                addHudStars(UInt16(id))
                score--
            }
        }
    }
    
    override func setupNeutral() {
        enumerateChildNodesWithName("neutral*"){ node, _ in
            let neutralNode = node as SKSpriteNode
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
        
        if remainingSlave == 0 && currentLevel == connection.maxLevel {
            var maxScore: Int = 0
            for (id, score) in connection.scoreBoard {
                if score > maxScore {
                    maxScore = score
                }
            }
            if maxScore == connection.scoreBoard[Int(myNodes.id)] {
                gameOver = true
                connection.sendGameOver()
                gameOver(won: true)
            }
        }
    }
    
    override func gameOver(#won: Bool) {
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.currentLevel = currentLevel
        gameOverScene.scaleMode = scaleMode
        gameOverScene.controller = connection.controller
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    override func scored() {
        self.remainingSlave--
        addHudStars(myNodes.id)
        if remainingSlave == 0 {
            checkGameOver()
            if (gameOver == false && connection.controller.currentLevel < connection.maxLevel){
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
    
    override func changeDest(){
        whichPos++
        destPointer.position = destPosList[whichPos % destPosList.count]
        destHeart.position = destPosList[whichPos % destPosList.count]
    }
}
