//
//  GamePoolScene.swift
//  OmniBall
//
//  Created by Fang on 4/21/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

class GamePoolScene: GameScene {
    
    var boundRect: CGRect!
    var wave = 1
    //var neutralList: [SKSpriteNode] = []
    var neutralPosList: [CGPoint] = []
    var renew = false
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        let url = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("pool", ofType: "mp3")!)
        player = AVAudioPlayer(contentsOfURL: url, error: nil)
        player.numberOfLoops = -1
        player.prepareToPlay()
        readyGo()
    }
    
    override func setupHUD() {
        super.setupHUD()
        let startPos = CGPoint(x: 100, y: size.height - 300)
        for var i = 0; i < slaveNum * 3; ++i {
            let minion = SKSpriteNode(imageNamed: "80x80_star_slot")
            minion.position = startPos + CGPoint(x: CGFloat(i) * (minion.size.width), y: 0)
            minion.position = hudLayer.convertPoint(minion.position, fromNode: self)
            hudMinions.append(minion)
            hudLayer.AddChild(minion)
            collectedMinions.append(false)
        }
    }
    
    override func setupNeutral() {
        enumerateChildNodesWithName("neutral*"){ node, _ in
            let neutralNode = node as! SKSpriteNode
//            self.neutralList.append(neutralNode)
            self.neutralPosList.append(neutralNode.position)
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
        let topWall = childNodeWithName("barTop") as! SKSpriteNode
        let bottomWall = childNodeWithName("barBottom") as! SKSpriteNode
        let leftWall = childNodeWithName("barLeft") as! SKSpriteNode
        let rightWall = childNodeWithName("barRight") as! SKSpriteNode
        boundRect = CGRect(x: leftWall.position.x, y: bottomWall.position.y, width: rightWall.position.x - leftWall.position.x, height: topWall.position.y - bottomWall.position.y)
//        debugDrawPlayableArea(boundRect)
    }
    
    func debugDrawPlayableArea(rect: CGRect) {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, rect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        AddChild(shape)
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
        renew = true
    }
    
    override func update(currentTime: CFTimeInterval) {
        if (renew == true) {
            player.pause()
            physicsWorld.speed = 0
            for var i = 0; i < neutralPosList.count; ++i {
                let node = SKSpriteNode(imageNamed: "staro")
                node.name = "neutral" + String(i)
                node.size = CGSize(width: 110, height: 110)
                node.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "staro"), size: CGSize(width: 110, height: 110))
                node.position = neutralPosList[i]
                
                node.physicsBody!.dynamic = false
                node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                node.physicsBody!.restitution = 1
                node.physicsBody!.linearDamping = 0
                node.physicsBody!.categoryBitMask = physicsCategory.target
                node.physicsBody!.contactTestBitMask = physicsCategory.Me
                self.neutralBalls[node.name!] = NeutralBall(node: node, lastCapture: 0)
                AddChild(node)
            }
            remainingSlave = neutralPosList.count
            renew = false
            myNodes.players[0].texture = SKTexture(imageNamed: getPlayerImageName(myNodes.color, true))
            cleanCapturedArrays()
            wave++
            readyGo()
        }
        super.update(currentTime)
    }
    
    override func scored() {
        super.scored()
        self.remainingSlave--
        addHudStars(myNodes.id)
        println("SCORED: \(remainingSlave)")
        if (remainingSlave == 0) {
            if (wave < 3) {
                connection.sendPause()
                paused()
            }
            else {
                checkGameOver()
            }
        }
    }
    
    func cleanCapturedArrays(){
        scheduleCaptureBy.removeAll(keepCapacity: false)
        scheduleToCapture.removeAll(keepCapacity: false)
        scheduleUpdateTime.removeAll(keepCapacity: false)
    }
    
    override func checkGameOver() {
        if remainingSlave == 0 && wave == 3{
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
        var score = 0
        for (name, slave) in myNodes.slaves {
            if !CGRectContainsPoint(boundRect, slave.node.position) {
                myNodes.successNodes += 1
                myNodes.score++
                connection.peersInGame.increaseScore(myNodes.id)
                let slaveName = name as NSString
                let index: Int = slaveName.substringFromIndex(7).toInt()!
                deCapList.append(slave.node)
                slave.node.RemoveFromParent()
                myNodes.sendDead(UInt16(index))
                score++
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
        
        for var i = 0; i < score; ++i {
            scored()
        }
    }
    
    override func readyGo(){
        var label = SKLabelNode(text: "Wave \(wave)!")
        label.fontName = "Chalkduster"
        label.fontSize = 200
        label.fontColor = UIColor.whiteColor()
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 - 150)
        AddChild(label)
        let action1 = SKAction.waitForDuration(1)
        let block1 = SKAction.runBlock{
            label.RemoveFromParent()
            self.physicsWorld.speed = 1
            self.player.play()
        }
        label.runAction(SKAction.sequence([action1, block1]))
    }

}
