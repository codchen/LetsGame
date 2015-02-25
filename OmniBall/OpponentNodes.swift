//
//  OpponentNodes.swift
//  OmniBall
//
//  Created by Fang on 2/19/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class OpponentNodes: Player {
    
    var lastCount: UInt32 = 0
    var deleteIndex: Int = -1
    var info:[nodeInfo] = []
    var updated: [Bool] = []
    var playerCount: UInt16 = 0
    
    init(id: UInt16, scene: GameScene) {
        super.init()
        self.id = id
        self.scene = scene
        self.color = PlayerColors(rawValue: Int(id))
        setUpPlayers(color)
    }
    
    override func addPlayer(node: SKSpriteNode) {
        players.append(node)
        info.append(nodeInfo(x: node.position.x, y: node.position.y, dx: 0, dy: 0, dt: 0, index: playerCount))
        updated.append(false)
        playerCount++
    }
    
    override func deletePlayer(index: Int) {
        if index >= players.count{
            return
        }
        playerCount--
        players.removeAtIndex(index)
        info.removeAtIndex(index)
        updated.removeAtIndex(index)
        for var idx = 0; idx < capturedIndex.count; ++idx {
            if capturedIndex[idx] > index {
                capturedIndex[idx]--
            }
        }
    }
    
    override func checkDead(){
        if deleteIndex != -1 {
            players[deleteIndex].removeFromParent()
            deletePlayer(deleteIndex)
            deleteIndex = -1
        }
    }
    
    override func setMasks(){
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node.physicsBody?.categoryBitMask = physicsCategory.Opponent
            node.physicsBody?.contactTestBitMask = physicsCategory.target
            
        }
    }
    
    func update_peer_dead_reckoning(){
        for var index = 0; index < count; ++index {
            if updated[index] == true {
                let currentNodeInfo = info[index]
                if closeEnough(CGPoint(x: info[index].x, y: info[index].y), point2: players[index].position) == true {
                    players[index].physicsBody!.velocity = CGVector(dx: info[index].dx, dy: info[index].dy)
                }
                else if farEnough(CGPoint(x: info[index].x, y: info[index].y), point2: players[index].position) == true {
                    players[index].position = CGPoint(x: info[index].x, y: info[index].y)
                    players[index].physicsBody!.velocity = CGVector(dx: info[index].dx, dy: info[index].dy)
                }
                
                else {
                    players[index].physicsBody!.velocity = CGVector(dx: info[index].dx + (info[index].x - players[index].position.x), dy: info[index].dy + (info[index].y - players[index].position.y))
                }
                updated[index] = false
            }
        }
    }
    
    func updatePeerPos(message: MessageMove) {
        if Int(message.index) >= count{
            return
        }
        if (message.count > lastCount){
            if Int(message.index) < count {
                lastCount = message.count
                info[Int(message.index)] = nodeInfo(x: CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index)
                updated[Int(message.index)] = true
            }
        }

    }
    
    override func updateCaptured(message: MessageCapture) {
        let slave = scene.childNodeWithName("neutral" + String(message.index)) as SKSpriteNode
        capture(Int(message.index), target: slave)
        lastCount = message.count
    }
    
    func closeEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        let offset = point1.distanceTo(point2)
        if offset >= 10{
            return false
        }
        return true
    }
    
    func farEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        let offset = point1.distanceTo(point2)
        if offset < 200{
            return false
        }
        return true
    }
}