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
        var execQ: dispatch_queue_t = dispatch_queue_create("org.omniball.oppospecs", DISPATCH_QUEUE_SERIAL)
        mutating func add(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat,
            dt: CGFloat, index: UInt16, sync: Bool) {
                if (sync == true) {
                    dispatch_sync(execQ){
                        self.info.append(nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index))
                        self.updated.append(false)
                    }
                }
                else{
                    dispatch_async(execQ){
                        self.info.append(nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index))
                        self.updated.append(false)
                    }
                }
        }
        mutating func update (x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat,
            dt: CGFloat, index: UInt16, sync: Bool){
                if (sync == true) {
                    dispatch_sync(execQ){
                        self.info[Int(index)] = nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index)
                        self.updated[Int(index)] = true
                    }
                }
                else{
                    dispatch_async(execQ){
                        self.info[Int(index)] = nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index)
                        self.updated[Int(index)] = true
                    }
                }
        }
        
        mutating func setUpdated(index: Int, update: Bool, sync: Bool) {
            if (sync == true) {
                dispatch_sync(execQ){
                    self.updated[index] = update
                }
            }
            else{
                dispatch_async(execQ){
                    self.updated[index] = update
                }
            }
        }
        
        mutating func getInfoPosition(index: Int) -> CGPoint {
            return CGPoint(x: info[index].x, y: info[index].y)
        }
        
        mutating func getInfoVelocity(index: Int) -> CGVector {
            return CGVector(dx: info[index].dx, dy: info[index].dy)
        }
        
        mutating func isUpdated(index: Int) -> Bool {
            return updated[index]
        }
    }
    
    struct SlaveSpecs {
        var info: Dictionary<String, nodeInfo> = Dictionary<String, nodeInfo>()
        var updated: Dictionary<String, Bool> = Dictionary<String, Bool>()
        var execQ: dispatch_queue_t = dispatch_queue_create("org.omniball.slavespecs", DISPATCH_QUEUE_SERIAL)
        mutating func update(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat,
            dt: CGFloat, index: UInt16, hasUpdated: Bool, sync: Bool) {
                if (sync == true) {
                    dispatch_sync(execQ){
                        let name = "neutral" + String(index)
                        if !hasUpdated || (hasUpdated && self.info[name] != nil) {
                            self.info[name] = nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index)
                            self.updated[name] = hasUpdated
                        }
                    }
                }
                else{
                    dispatch_async(execQ){
                        let name = "neutral" + String(index)
                        if !hasUpdated || (hasUpdated && self.info[name] != nil) {
                            self.info[name] = nodeInfo(x: x, y: y, dx: dx, dy: dy, dt: dt, index: index)
                            self.updated[name] = hasUpdated
                        }
                    }
                }
        }
        
        mutating func isUpdated(name: String) -> Bool {
            if updated[name] == nil {
                return false
            }
            return updated[name]!
        }
        
        mutating func getInfoPosition(name: String) -> CGPoint {
            return CGPoint(x: info[name]!.x, y: info[name]!.y)
        }
        
        mutating func getInfoVelocity(name: String) -> CGVector {
            return CGVector(dx: info[name]!.dx, dy: info[name]!.dy)
        }
        
        mutating func setUpdated(name: String, update: Bool, sync: Bool) {
            if (sync == true) {
                dispatch_sync(execQ){
                    self.updated[name] = update
                }
            }
            else{
                dispatch_async(execQ){
                    self.updated[name] = update
                }
            }
        }
        
        mutating func delete(name: String, sync: Bool) {
            if (sync == true) {
                dispatch_sync(execQ){
                    self.info[name] = nil
                    self.updated[name] = nil
                }
            }
            else {
                dispatch_async(execQ){
                    self.info[name] = nil
                    self.updated[name] = nil
                }
            }
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
        specs.add(node.position.x, y: node.position.y, dx: 0, dy: 0, dt: 0, index: playerCount, sync: true)
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
            slaveSpecs.update(target.position.x, y: target.position.y, dx: target.physicsBody!.velocity.dx, dy: target.physicsBody!.velocity.dy, dt: 0, index: UInt16(index), hasUpdated: false, sync: true)
        }
    }
    
    override func decapture(target: SKSpriteNode) {
        if slaves[target.name!] != nil {
            slaves[target.name!] = nil
            slaveSpecs.delete(target.name!, sync: true)
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
                specs.setUpdated(index, update: false, sync: true)
            }
        }
        
        // update opponent slave nodes
        for (name, slave) in slaves {
            if slaves[name] != nil {
                if slaveSpecs.isUpdated(name) {
                    if closeEnough(slaveSpecs.getInfoPosition(name), point2: slaves[name]!.node.position){
                        slaves[name]!.node.physicsBody!.velocity = slaveSpecs.getInfoVelocity(name)
                    }
                    else if farEnough(slaveSpecs.getInfoPosition(name), point2: slaves[name]!.node.position){
                        slaves[name]!.node.position = slaveSpecs.getInfoPosition(name)
                        slaves[name]!.node.physicsBody!.velocity = slaveSpecs.getInfoVelocity(name)
                    }
                    else {
                        slaves[name]!.node.physicsBody!.velocity = slaveSpecs.getInfoVelocity(name) + CGVector(point: slaveSpecs.getInfoPosition(name) - slaves[name]!.node.position)
                    }
                    slaveSpecs.setUpdated(name, update: false, sync: true)
                }

            } else {
                println("YAY it's nil!")
            }
        }
    }
    
    func updatePeerPos(message: MessageMove) {
        if (message.count > lastCount){
            lastCount = message.count
            if message.isSlave {
                slaveSpecs.update(CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index, hasUpdated: true, sync: false)
            } else {
                specs.update(CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index, sync: false)
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