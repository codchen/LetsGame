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
    var msgCount: UInt32 = 0
    var isSelected: Bool = false
    var selectedNode: SKSpriteNode!
    var launchTime: NSDate!
    var launchPoint: CGPoint!
    
    init(connection: ConnectionManager, scene: GameScene) {
        super.init()
        
        self.connection = connection
        self.scene = scene
        self.id = connection.playerID
        self.color = PlayerColors(rawValue: id)
        setUpPlayers(color)
    }
    
    override func addPlayer(node: SKSpriteNode) {
        players.append(node)
    }
    
    override func deletePlayer(index: Int) {
        players[index].removeFromParent()
        players.removeAtIndex(index)
        sendDead(index)
    }
    
    override func checkDead(){
        for var index = 0; index < count; ++index{
            if withinBorder(players[index].position) == false{
                deadNodes.insert(index, atIndex: 0)
            }
        }
        for index in self.deadNodes{
            deletePlayer(index)
        }
        
        deadNodes = []
    }
    
    func touchesBegan(location: CGPoint) {
    	for node in players {
            if node.containsPoint(location){
                selectedNode = node
                selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, isSelected: true))
                    isSelected = true
                    break
            }
        }
            
    }
    
    func touchesEnded(location: CGPoint){
        let now = NSDate()
        let offset: CGPoint = (location - launchPoint) / CGFloat(now.timeIntervalSinceDate(launchTime!))
        selectedNode.physicsBody?.velocity = CGVector(dx: offset.x / 1.5, dy: offset.y / 1.5)
        isSelected = false
        selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, isSelected: false))
        selectedNode = nil
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
    
    func sendDead(index: Int){
        println("I'm dead")
        connection.sendDeath(index)
    }
    
    func sendMove(){
        for var index = 0; index < count; ++index{
            connection.sendMove(Float(players[index].position.x), y: Float(players[index].position.y), dx: Float(players[index].physicsBody!.velocity.dx), dy: Float(players[index].physicsBody!.velocity.dy), count: msgCount, index: UInt16(index), dt: NSDate().timeIntervalSince1970)
            msgCount++
        }
    }
}
