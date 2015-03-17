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
    var isSelected: Bool = false
    var selectedNode: SKSpriteNode!
    var launchTime: NSDate!
    var launchPoint: CGPoint!
    let maxSpeed:CGFloat = 1500
    var score = 0
    
    init(connection: ConnectionManager, scene: GameScene) {
        super.init()
        
        self.connection = connection
        self.scene = scene
        self.id = connection.playerID
        self.color = PlayerColors(rawValue: Int(id))
        score = connection.scoreBoard[Int(self.id)]!
        setUpPlayers(color)
        selectedNode = players[0]
        for player in players{
            player.texture = SKTexture(imageNamed: getPlayerImageName(color, true))
        }
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
                isSelected = false
                selectedNode = players[0]
            }
            slaves[target.name!] = nil
        }
    }
    
    override func capture(target: SKSpriteNode, capturedTime: NSTimeInterval) {
        super.capture(target, capturedTime: capturedTime)
        target.texture = SKTexture(imageNamed: getSlaveImageName(color!, true))
    }
    
//    override func checkDead(){
//        for var index = 0; index < count; ++index{
//            if withinBorder(players[index].position) == false{
//                deadNodes.insert(index, atIndex: 0)
//            }
//        }
//        for index in self.deadNodes{
//            players[index].removeFromParent()
//            deletePlayer(index)
//            sendDead(UInt16(index))
//        }
//        
//        deadNodes = []
//    }
    
    override func setMasks(){
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node.physicsBody?.categoryBitMask = physicsCategory.Me
            node.physicsBody?.contactTestBitMask = physicsCategory.target
            
        }
    }
    
    func checkOutOfBound(){
        
        for (name, slave) in slaves {
            if slave.node.intersectsNode(scene.destHeart) {
                successNodes += 1
                score++
                connection.scoreBoard[Int(id)]!++
                let slaveName = name as NSString
                let index: Int = slaveName.substringFromIndex(7).toInt()!
                decapture(slave.node)
                slave.node.removeFromParent()
                sendDead(UInt16(index))
                scene.scored()
            }
        }
    }
    
    func touchesBegan(location: CGPoint) {
    	for node in players {
            if closeEnough(location, node.position, CGFloat(250)) == true{
                touchesBeganHelper(node, location: location, isSlave: false)
                break
            }
        }
        
        for (name, slave) in slaves {
            let node = scene.childNodeWithName(name) as SKSpriteNode
            if node.containsPoint(location){
                touchesBeganHelper(node, location: location, isSlave: true)
                break
            }
        }
        
        if isSelected {
            if closeEnough(location, selectedNode.position, CGFloat(250)) == true{
                launchPoint = location
                launchTime = NSDate()
            }
        }

    }
    
    func touchesBeganHelper(node: SKSpriteNode, location: CGPoint, isSlave: Bool) {
//        if selectedNode.name!.hasPrefix("neutral"){
//            selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, false))
//        } else {
//            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, false))
//        }
        selectedNode = node
        
//        if isSlave {
//            selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, true))
//        } else {
//            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, true))
//        }
        
        isSelected = true
        
    }

    
    func touchesEnded(location: CGPoint){
        
        if (isSelected && launchTime != nil && launchPoint != nil) {
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
}
