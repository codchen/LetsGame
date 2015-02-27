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
    
    init(connection: ConnectionManager, scene: GameScene) {
        super.init()
        
        self.connection = connection
        self.scene = scene
        self.id = connection.playerID
        self.color = PlayerColors(rawValue: Int(id))
        setUpPlayers(color)
        selectedNode = players[0]
    }
    
    override func addPlayer(node: SKSpriteNode) {
        players.append(node)
    }
    
    override func deletePlayer(index: Int) {
        if index >= players.count{
            return
        }
        players.removeAtIndex(index)
        for var idx = 0; idx < capturedIndex.count; ++idx {
            if capturedIndex[idx] > index {
                capturedIndex[idx]--
            }
        }
    }
    
    override func checkDead(){
        for var index = 0; index < count; ++index{
            if withinBorder(players[index].position) == false{
                deadNodes.insert(index, atIndex: 0)
            }
        }
        for index in self.deadNodes{
            players[index].removeFromParent()
            deletePlayer(index)
            sendDead(UInt16(index))
        }
        
        deadNodes = []
    }
    
    override func setMasks(){
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node.physicsBody?.categoryBitMask = physicsCategory.Me
            node.physicsBody?.contactTestBitMask = physicsCategory.target
            
        }
    }
    
    func checkOutOfBound(){
        for var i = 0; i < count; ++i{
            if players[i].position.y > 2733{
                players[i].physicsBody!.velocity = CGVector(dx: 0, dy: 0)
                if players[i].name?.hasPrefix("neutral") == true{
                    players[i].removeFromParent()
                    deletePlayer(i)
                    sendDead(UInt16(i))
                    successNodes += 1
                }
                else{
                    players[i].position = bornPos[i]
                }
            }
        }
    }
    
    func touchesBegan(location: CGPoint) {
    	for node in players {
            if node.containsPoint(location){
                selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, isSelected: false))
                selectedNode = node
                if selectedNode.name!.hasPrefix("neutral") {
                    selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, isSelected: true))
                } else {
                    selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, isSelected: true))
                }
                break
            }
        }
    }

    
    func touchesEnded(location: CGPoint){
        let now = NSDate()
        var offset: CGPoint = (location - launchPoint) / CGFloat(now.timeIntervalSinceDate(launchTime!))
        if offset.length() > maxSpeed{
            offset.normalize()
            offset.x = offset.x * maxSpeed
            offset.y = offset.y * maxSpeed
        }
        selectedNode.physicsBody?.velocity = CGVector(dx: offset.x / 1.5, dy: offset.y / 1.5)
//        isSelected = false
//        selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, isSelected: false))
//        selectedNode = nil
        launchTime = nil
        launchPoint = nil
        sendMove()
    }
    
    func withinBorder(pos: CGPoint) -> Bool{
        if pos.x < 0 || pos.x > scene.size.width * 2 || pos.y < scene.margin || pos.y > scene.size.height * 2 - scene.margin {
            return false
        }
        return true
    }
    
    override func updateCaptured(message: MessageCapture) {
        let index = Int(message.index)
        decapture(index)
    }
    
    func sendDead(index: UInt16){
        connection.sendDeath(index, count: msgCount)
        msgCount++
    }
    
    func sendMove(){
        for var index = 0; index < count; ++index{
            connection.sendMove(Float(players[index].position.x), y: Float(players[index].position.y), dx: Float(players[index].physicsBody!.velocity.dx), dy: Float(players[index].physicsBody!.velocity.dy), count: msgCount, index: UInt16(index), dt: NSDate().timeIntervalSince1970)
            msgCount++
        }
    }
}
