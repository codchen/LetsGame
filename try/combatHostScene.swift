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

    var peers: Dictionary<String, CMAccelerometerData!> = Dictionary<String, CMAccelerometerData!>()
    var peersNumber: Dictionary<String, Int> = Dictionary<String, Int>()
    var number = 0
    
    let maxForce = CGFloat(300)
    let staticFriction = CGFloat(0.8)
    let kineticFriction = CGFloat(0.4)
    
    var force = CGVector(dx: 0, dy: 0)
    var moveDir = CGVector(dx: 0, dy: 0)
    var friction = CGFloat(0)
    var frictionForce = CGVector(dx: 0, dy: 0)

    
    override func didMoveToView(view: SKView) {
        identity = "Host"
        
        me = SKSpriteNode(imageNamed: "50x50_ball")
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: -me.size.width, y: playableMargin - me.size.height, width: size.width + me.size.width * 2, height: size.height - playableMargin * 2 + me.size.height * 2)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)

        me.name = "ball" + connection.session.myPeerID.displayName
        me.position = randomPos()
        
        nodesInfo[me.name!] = nodeInfo(node: me, bornPos: me.position, dropped: false)
        me.physicsBody = SKPhysicsBody(circleOfRadius: me.size.width/2)
        
        nodes.append(me)
        
        peersNumber[me.name!] = number
        number++
        
        addChild(me)
    }
    
    func moveFromAcceleration(){
        if motionManager.accelerometerData == nil{
            return
        }
        force.dx = CGFloat(motionManager.accelerometerData.acceleration.y) * maxForce
        force.dy = -1 * CGFloat(motionManager.accelerometerData.acceleration.x) * maxForce

        if ifMove(force, mass: me.physicsBody!.mass){
            if me.physicsBody!.velocity.length() < 500{
                me.physicsBody?.applyForce(force)
            }
        }
        applyFriction(me)
    }
    
    func movePeers(){
        for (name, data) in peers{
            if data == nil{
                continue
            }
            var peerForce = CGVector(dx: CGFloat(data.acceleration.y) * maxForce, dy: CGFloat(-1 * data.acceleration.x) * maxForce)
            if ifMove(peerForce, mass: me.physicsBody!.mass){
                if nodesInfo[name]!.node.physicsBody!.velocity.length() < 500{
                    nodesInfo[name]!.node.physicsBody!.applyForce(peerForce)
                }
            }
            applyFriction(nodesInfo[name]!.node)
        }
    }
    
    func ifMove(force: CGVector, mass: CGFloat) -> Bool{
        if force.length() < mass * 9.8 * staticFriction{
            return false;
        }
        return true;
    }
    
    func applyFriction(node: SKSpriteNode){
        if node.physicsBody!.velocity.length() > 0.5{
            node.physicsBody!.applyForce(node.physicsBody!.velocity.normalized() * CGFloat(-1 * node.physicsBody!.mass * 9.8 * kineticFriction))
        }
    }
    
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
            connection.sendMove(Float(everyNode.physicsBody!.velocity.dx), dy: Float(everyNode.physicsBody!.velocity.dy),
                posX: Float(everyNode.position.x), posY: Float(everyNode.position.y), rotate: Float(everyNode.zRotation), dt: Float(dt), number: peersNumber[everyNode.name!]!)
        }
    }
    
    override func updatePeers(data: NSData, peer: String){
        peers[peer] = NSKeyedUnarchiver.unarchiveObjectWithData(data) as CMAccelerometerData
    }
    
    override func addPlayer(data: NSData, peer: String){
        var node = SKSpriteNode(imageNamed: "50x50_ball")
        node.name = peer
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        peerList.append(peer)
        nodesInfo[peer] = nodeInfo(node: node, bornPos: randomPos(), dropped: false)
        nodes.append(node)
        peers[peer] = NSKeyedUnarchiver.unarchiveObjectWithData(data) as CMAccelerometerData
        peersNumber[peer] = number
        number++
        addChild(node)
    }
}