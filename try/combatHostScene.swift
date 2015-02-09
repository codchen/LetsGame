//
//  combatHostScene.swift
//  try
//
//  Created by Xiaoyu Chen on 1/30/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit
import CoreMotion


class combatHostScene: combatScene{
    
    var me: SKSpriteNode!

    var peers: Dictionary<String, Array<MessageRawData>> = Dictionary<String, Array<MessageRawData>>()
    var peersNumber: Dictionary<String, UInt32> = Dictionary<String, UInt32>()
    var number: UInt32 = 0
    
    let maxSpeed = CGFloat(750)
//    let staticFriction = CGFloat(0.8)
//    let kineticFriction = CGFloat(0.4)
//    
//    var force = CGVector(dx: 0, dy: 0)
//    var moveDir = CGVector(dx: 0, dy: 0)
//    var friction = CGFloat(0)
//    var frictionForce = CGVector(dx: 0, dy: 0)

    
    override func didMoveToView(view: SKView) {
        identity = "Host"
        
        me = SKSpriteNode(imageNamed: "50x50_ball")
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
		println(playableRect)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)

        me.name = "ball" + connection.session.myPeerID.displayName
        me.position = randomPos()
        
        nodesInfo[me.name!] = nodeInfo(node: me, bornPos: me.position, dropped: false)
        me.physicsBody = SKPhysicsBody(circleOfRadius: me.size.width/2)
        me.physicsBody?.restitution = 1.0
        me.physicsBody?.allowsRotation = false
        nodes.append(me)
        
        peersNumber[me.name!] = number
        number++
        
        addChild(me)
    }
    
    func moveFromAcceleration(){
        if motionManager.accelerometerData == nil{
            return
        }
        
        var accel2D = CGPointZero
        accel2D.x = CGFloat(motionManager.accelerometerData.acceleration.y)
        accel2D.y = -1 * CGFloat(motionManager.accelerometerData.acceleration.x)
        
		if accel2D.x != 0 || accel2D.y != 0{
            me.physicsBody?.velocity = CGVector(dx: CGFloat(accel2D.x * maxSpeed), dy: CGFloat(accel2D.y * maxSpeed))
        }
    }
    
    func movePeers(){
        for (name, data) in peers{
            if data.isEmpty {
                continue
            }
            var temp = data
            var rawData = temp.removeAtIndex(0)
            var peerVel = CGVector(dx: CGFloat(rawData.dy) * maxSpeed, dy: CGFloat(-1 * rawData.dx) * maxSpeed)
            let node = childNodeWithName(name) as SKSpriteNode
            node.physicsBody?.velocity = peerVel
            peers[name] = temp
        }
    }
    
//    func ifMove(force: CGVector, mass: CGFloat) -> Bool{
//        if force.length() < mass * 9.8 * staticFriction{
//            return false;
//        }
//        return true;
//    }
//    
//    func applyFriction(node: SKSpriteNode){
//        if node.physicsBody!.velocity.length() > 0.5{
//            node.physicsBody!.applyForce(node.physicsBody!.velocity.normalized() * CGFloat(-1 * node.physicsBody!.mass * 9.8 * kineticFriction))
//        }
//    }
    
//    func checkWrap(){
//        if me.position.x > size.width + me.size.width / 2.0 {
//            me.position.x = -me.size.width / 2.0
//        } else if me.position.x < -me.size.width / 2.0 {
//            me.position.x = size.width + me.frame.size.width / 2.0
//        }
//        
//        if me.position.y > size.height - margin + me.size.height / 2.0 {
//            me.position.y = -me.size.height / 2.0
//        } else if me.position.y < -me.size.height / 2.0 {
//            me.position.y = size.height - margin + me.size.height / 2.0
//        }
//    }

    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        moveFromAcceleration()
        movePeers()
        
        checkDrop()
        
        for everyNode in nodes{
            println("Sent pos \(everyNode.name): \(everyNode.position) \(peersNumber[everyNode.name!])")
            connection.sendMove(Float(everyNode.physicsBody!.velocity.dx), dy: Float(everyNode.physicsBody!.velocity.dy), posX: Float(everyNode.position.x), posY: Float(everyNode.position.y), rotate: Float(everyNode.zRotation), dt: Float(dt), number: peersNumber[everyNode.name!]!)
        }
    }
    
    override func updatePeers(data: NSData, peer: String){
        var message = UnsafePointer<MessageRawData>(data.bytes).memory
        peers[peer]?.append(message)
    }
    
    override func addPlayer(data: NSData, peer: String){
        var message = UnsafePointer<MessageRawData>(data.bytes).memory
        var node = SKSpriteNode(imageNamed: "50x50_ball")
        node.name = peer
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		node.physicsBody?.restitution = 1.0
        peerList.append(peer)
        let pos = randomPos()
        node.position = pos
        nodesInfo[peer] = nodeInfo(node: node, bornPos: pos, dropped: false)
        nodes.append(node)
        
        peers[peer] = Array<MessageRawData>()
        peers[peer]?.append(message)
        
        peersNumber[peer] = number
        number++
        
        addChild(node)
    }
}