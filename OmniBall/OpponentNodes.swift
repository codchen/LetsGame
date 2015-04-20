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
    
    struct OpponentSpecs {
        var info: [nodeInfo] = []
        var updated: [Bool] = []
//        let execQ: dispatch_queue_t = dispatch_queue_create("org.omniball.oppospecs", DISPATCH_QUEUE_SERIAL)
        mutating func add(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat,
            dt: CGFloat, index: UInt16) {
//                dispatch_sync(execQ){
                    self.info.append(nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index))
                    self.updated.append(false)
//                }
        }
        mutating func update (x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat,
            dt: CGFloat, index: UInt16){
//                dispatch_sync(execQ){
                    self.info[Int(index)] = nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index)
                    self.updated[Int(index)] = true
//                }
        }
        
        mutating func setUpdated(index: Int, update: Bool) {
//            dispatch_sync(execQ){
                self.updated[index] = update
//            }
        }
        
		func getInfoPosition(index: Int) -> CGPoint {
            var result: CGPoint!
//            dispatch_sync(execQ) {
                result = CGPoint(x: self.info[index].x, y: self.info[index].y)
//            }
            return result
        }
        
        func getInfoVelocity(index: Int) -> CGVector {
            var result: CGVector!
//            dispatch_sync(execQ) {
                result = CGVector(dx: self.info[index].dx, dy: self.info[index].dy)
//            }
            return result
        }
        
        func isUpdated(index: Int) -> Bool {
            var result: Bool!
//            dispatch_sync(execQ) {
                result = self.updated[index]
//            }
            return result
        }
    }
    
    struct SlaveSpecs {
        var info: Dictionary<String, nodeInfo> = Dictionary<String, nodeInfo>()
        var updated: Dictionary<String, Bool> = Dictionary<String, Bool>()
//        let execQ: dispatch_queue_t = dispatch_queue_create("org.omniball.slavespecs", DISPATCH_QUEUE_SERIAL)
        mutating func update(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat,
            dt: CGFloat, index: UInt16, hasUpdated: Bool) {
//            dispatch_sync(execQ){
                let name = "neutral" + String(index)
                if let node = self.info[name] {
                    self.info.updateValue(nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index), forKey: name)
                    self.updated.updateValue(hasUpdated, forKey: name)
                } else if !hasUpdated {
                    self.info.updateValue(nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index), forKey: name)
                    self.updated.updateValue(hasUpdated, forKey: name)
                }
//            }
        }
        
        func isUpdated(name: String) -> Bool {
            var result = false
//            dispatch_sync(execQ) {
                if self.updated[name] != nil{
                    result = self.updated[name]!
                }
//            }
            return result
        }
        
        func getInfoPosition(name: String) -> CGPoint {
            var result: CGPoint!
//            dispatch_sync(execQ) {
                result = CGPoint(x: self.info[name]!.x, y: self.info[name]!.y)
//            }
            return result
        }
        
        func getInfoVelocity(name: String) -> CGVector {
            var result: CGVector!
//            dispatch_sync(execQ) {
                result = CGVector(dx: self.info[name]!.dx, dy: self.info[name]!.dy)
//            }
            return result
        }
        
        mutating func setUpdated(name: String, update: Bool) {
//            dispatch_sync(execQ){
                self.updated.updateValue(update, forKey: name)
//            }
        }
        
        mutating func delete(name: String) {
//            dispatch_sync(execQ){
                self.info.removeValueForKey(name)
                self.updated.removeValueForKey(name)
//            }
        }
    }
    
    var lastCount: UInt32 = 0
    var deleteIndex: Int = -1
    var specs: OpponentSpecs = OpponentSpecs()
    var slaveSpecs: SlaveSpecs = SlaveSpecs()
    var playerCount: UInt16 = 0
    let closeOffset: CGFloat = 10
    let farOffset: CGFloat = 500
    
    init(id: UInt16, scene: GameScene) {
        super.init()
        self.id = id
        self.scene = scene
        self.color = PlayerColors(rawValue: Int(id))
        setUpPlayers(color)
    }
    
    override func addPlayer(node: SKSpriteNode) {
        players.append(node)
        specs.add(node.position.x, y: node.position.y, dx: 0, dy: 0, dt: 0, index: playerCount)
        playerCount++
    }
    
    override func deletePlayer(index: Int) {
        if index >= players.count{
            return
        }
        playerCount--
        players.removeAtIndex(index)
//        info.removeAtIndex(index)
//        updated.removeAtIndex(index)
    }
    
    func checkDead(){
        if deleteIndex != -1 {
            let name = "neutral" + String(deleteIndex)
            if let node = scene.childNodeWithName(name) as? SKSpriteNode {
                decapture(node)
                node.removeFromParent()
                deleteIndex = -1
                scene.addHudStars(self.id)
                scene.changeDest()
            }
        }
    }
    
    override func setMasks(){
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node.physicsBody?.categoryBitMask = physicsCategory.Opponent
            node.physicsBody?.contactTestBitMask = physicsCategory.target | physicsCategory.Me | physicsCategory.wall
        }
    }
    
    override func capture(target: SKSpriteNode, capturedTime: NSTimeInterval) {
        if slaves[target.name!] == nil {
            target.physicsBody?.dynamic = true
            let name = target.name! as NSString
            let index = name.substringFromIndex(7).toInt()!
            slaves[target.name!] = NeutralBall(node: target, lastCapture: capturedTime)
            captureAnimation(target, isOppo: true)
            slaveSpecs.update(target.position.x, y: target.position.y, dx: target.physicsBody!.velocity.dx, dy: target.physicsBody!.velocity.dy, dt: 0, index: UInt16(index), hasUpdated: false)
        }
    }
    
    override func decapture(target: SKSpriteNode) {
        if let slave = slaves[target.name!] {
            slaves.removeValueForKey(target.name!)
            slaveSpecs.delete(target.name!)
        }
    }
    
    func update_peer_dead_reckoning(){
        
        // updated opponent nodes
        for var index = 0; index < count; ++index {
            if specs.isUpdated(index) {
//                let currentNodeInfo = info[index]
                if closeEnough(specs.getInfoPosition(index), point2: players[index].position){
                    players[index].physicsBody!.velocity = specs.getInfoVelocity(index)
                }
                else if farEnough(specs.getInfoPosition(index), point2: players[index].position){
                    players[index].position = specs.getInfoPosition(index)
                    players[index].physicsBody!.velocity = specs.getInfoVelocity(index)
                }
                
            	else {
                	players[index].physicsBody!.velocity = specs.getInfoVelocity(index) + CGVector(point: specs.getInfoPosition(index) - players[index].position)
                }
                specs.setUpdated(index, update: false)
            }
        }
        
        // update opponent slave nodes
        for (name, slave) in slaves {
            if let slaveNode = slaves[name] {
                if slaveSpecs.isUpdated(name) {
                    if closeEnough(slaveSpecs.getInfoPosition(name), point2: slaveNode.node.position){
                        slaveNode.node.physicsBody!.velocity = slaveSpecs.getInfoVelocity(name)
                    }
                    else if farEnough(slaveSpecs.getInfoPosition(name), point2: slaveNode.node.position){
                        slaveNode.node.position = slaveSpecs.getInfoPosition(name)
                        slaveNode.node.physicsBody!.velocity = slaveSpecs.getInfoVelocity(name)
                    }
                    else {
                        slaveNode.node.physicsBody!.velocity = slaveSpecs.getInfoVelocity(name) + CGVector(point: slaveSpecs.getInfoPosition(name) - slaveNode.node.position)
                    }
                    slaveSpecs.setUpdated(name, update: false)
                }
            }
        }
    }
    
    func updatePeerPos(message: MessageMove) {
        if (message.count > lastCount){
            lastCount = message.count
            if message.isSlave {
                slaveSpecs.update(CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index, hasUpdated: true)
            } else {
                specs.update(CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index)
            }
            
        }

    }
    
    func updateReborn(message: MessageReborn) {
        let index: Int = Int(message.index)
        players[index].physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        players[index].position = bornPos[index]
    }
    
    func closeEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        let offset = point1.distanceTo(point2)
        if offset >= closeOffset {
            return false
        }
        return true
    }
    
    func farEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        let offset = point1.distanceTo(point2)
        if offset < farOffset {
            return false
        }
        return true
    }
}