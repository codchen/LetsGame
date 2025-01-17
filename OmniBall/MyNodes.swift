//
//  MyNodes.swift
//  OmniBall
//
//  Created by Fang on 2/19/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class MyNodes: Player {
    
    let connection: ConnectionManager!
    var deadNodes:[Int] = []
    var successNodes: Int = 0
    var msgCount: UInt32 = 0
//    var isSelected: Bool = false
    var selectedNode: SKSpriteNode!
    var launchTime: NSDate!
    var launchPoint: CGPoint!
    let maxSpeed:CGFloat = 1500
    var score = 0
    
    init(connection: ConnectionManager, scene: GameScene) {
        self.connection = connection
        super.init()
        
        self.scene = scene
        self.id = connection.me.playerID
        if (Int(id) >= 0 && Int(id) <= 3) {
            self.color = PlayerColors(rawValue: Int(id))
        }
        else{
            self.color = PlayerColors(rawValue: 0)
        }
        score = connection.me.score
        setUpPlayers(color)
        selectedNode = players[0]
    	selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, true))
        
    }
    
    override func addPlayer(node: SKSpriteNode) {
        players.append(node)
    }
    
    override func deletePlayer(index: Int) {
        if index >= players.count{
            return
        }
        players.removeAtIndex(index)
    }
    
    override func decapture(target: SKSpriteNode) {
        if slaves[target.name!] != nil {
            if target == selectedNode {
//                isSelected = false
                selectedNode = players[0]
                selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, true))
            }
            slaves[target.name!] = nil
            if scene.enableSound {
                scene.runAction(scene.loseStarSound)
            }
        }
    }
    
    override func capture(target: SKSpriteNode, capturedTime: NSTimeInterval) {
        super.capture(target, capturedTime: capturedTime)
//        target.texture = SKTexture(imageNamed: getSlaveImageName(color!, true))
        if self.selectedNode.name!.hasPrefix("neutral"){
            self.selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(self.color, false))
        } else {
            self.selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(self.color, false))
        }
        self.selectedNode = target
        captureAnimation(target, isOppo: false)
        scene.runAction(scene.catchStarSound)
    }
    
    override func setMasks(){
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node.physicsBody?.categoryBitMask = physicsCategory.Me
            node.physicsBody?.contactTestBitMask = physicsCategory.target | physicsCategory.Opponent | physicsCategory.wall
            
        }
    }
    
    func touchesBegan(location: CGPoint) {
    	for node in players {
            if closeEnough(location, node.position, CGFloat(250)) == true{
                touchesBeganHelper(node, location: location, isSlave: false)
                launchPoint = location
                launchTime = NSDate()
                break
            }
        }
        
        for (name, slave) in slaves {
            if let node = scene.childNodeWithName(name) as? SKSpriteNode {
                if closeEnough(location, node.position, CGFloat(280)) == true {
                    touchesBeganHelper(node, location: location, isSlave: true)
                    launchPoint = location
                    launchTime = NSDate()
                    break
                }
            }
        }

    }
    
    func touchesBeganHelper(node: SKSpriteNode, location: CGPoint, isSlave: Bool) {
        if selectedNode.name!.hasPrefix("neutral"){
            selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, false))
        } else {
            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, false))
        }
        selectedNode = node
        
        if isSlave {
            selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, true))
        } else {
            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, true))
        }
//        isSelected = true
        
    }

    
    func touchesEnded(location: CGPoint){
        
        if (launchTime != nil && launchPoint != nil) {
        	let now = NSDate()
        	var offset: CGPoint = (location - launchPoint)/CGFloat(now.timeIntervalSinceDate(launchTime!))
        	if offset.length() > maxSpeed{
        		offset.normalize()
        		offset.x = offset.x * maxSpeed
       		 	offset.y = offset.y * maxSpeed
       	 	}
        	selectedNode.physicsBody?.velocity = CGVector(dx: offset.x / 2.3, dy: offset.y / 2.3)
        	launchTime = nil
            launchPoint = nil
        	sendMove()
        }
    }
    
    func withinBorder(pos: CGPoint) -> Bool{
        if pos.x < 0 || pos.x > scene.size.width * 2 || pos.y < scene.margin || pos.y > scene.size.height * 2 - scene.margin {
            return false
        }
        return true
    }
    
    func sendDead(index: UInt16){
        connection.sendDeath(index, count: msgCount)
        msgCount++
    }
    
    func sendMove(){
        
        // send move of myPlayer
        for var index = 0; index < count; ++index{
            sendMoveHelper(players[index], index: UInt16(index), isSlave: false)
        }
        
        // send move of my slaves
        for (name, slave) in slaves {
            let slaveNode = slave.node
            let name: NSString = slaveNode.name! as NSString
            let index: Int = name.substringFromIndex(7).toInt()!
            sendMoveHelper(slaveNode, index: UInt16(index), isSlave: true)
        }
    }
    
    func sendMoveHelper(node: SKSpriteNode, index: UInt16, isSlave: Bool) {
        connection.sendMove(Float(node.position.x), y: Float(node.position.y), dx: Float(node.physicsBody!.velocity.dx), dy: Float(node.physicsBody!.velocity.dy), count: msgCount, index: index, dt: NSDate().timeIntervalSince1970, isSlave: isSlave)
        msgCount++

    }
    
    override func captureAnimation(target: SKSpriteNode, isOppo: Bool){
        let originalTexture = SKTexture(imageNamed: getSlaveImageName(color!, false))
        let changedTexture = SKTexture(imageNamed: getSlaveImageName(color!, true))
        let block1 = SKAction.runBlock {
            target.texture = originalTexture
        }
        let block2 = SKAction.runBlock {
            target.texture = changedTexture
        }
        let wait = SKAction.waitForDuration(0.23)
        var flashAction: SKAction!
        if isOppo {
            flashAction = SKAction.sequence([block2, wait, block1, wait])
        } else {
            flashAction = SKAction.sequence([block1, wait, block2, wait])
        }
        let block3 = SKAction.runBlock {
            if self.selectedNode.name! == target.name! {
                target.texture =  SKTexture(imageNamed: getSlaveImageName(self.color!, true))
            }
            else {
                 SKTexture(imageNamed: getSlaveImageName(self.color!, false))
            }
        }
        target.removeAllActions()
        target.runAction(SKAction.sequence([SKAction.repeatAction(flashAction, count: 4), block3]))
    }
}
