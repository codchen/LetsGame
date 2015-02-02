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


class combatClientScene: combatScene{
    
    //var peerNode: SKSpriteNode!
    var numberPeers: Dictionary<Int, String> = Dictionary<Int, String>()
    
    override func didMoveToView(view: SKView) {
        identity = "Client"
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: -50, y: playableMargin - 50, width: size.width + 50 * 2, height: size.height - playableMargin * 2 + 50 * 2)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
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
        
        checkDrop()
        
//        if nodes.count == 1{
//            println(nodes[0].name)
//            println(nodes[0].position.x)
//        }
        
        if let data = motionManager.accelerometerData{
            let toSend = NSKeyedArchiver.archivedDataWithRootObject(data)
            connection.sendToHost(toSend)
        }
    }
    
    override func updatePeers(data: NSData, peer: String){
        var message = UnsafePointer<MessageMove>(data.bytes).memory
        var node = childNodeWithName(String(message.number)) as SKSpriteNode
        node.position = CGPoint(x: CGFloat(message.posX), y: CGFloat(message.posY))
        //println(node.position.x)
        node.physicsBody!.velocity = CGVector(dx: CGFloat(message.dx), dy: CGFloat(message.dy))
    }
    
    override func addPlayer(data: NSData, peer: String){
        var message = UnsafePointer<MessageMove>(data.bytes).memory
        var node = SKSpriteNode(imageNamed: "50x50_ball")
        node.name = String(message.number)
        node.position = CGPoint(x: CGFloat(message.posX), y: CGFloat(message.posY))
        peerList.append(node.name!)
        nodesInfo[node.name!] = nodeInfo(node: node, bornPos: node.position, dropped: false)
        nodes.append(node)
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody!.velocity = CGVector(dx: CGFloat(message.dx), dy: CGFloat(message.dy))
        addChild(node)
    }
}
