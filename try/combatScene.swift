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

struct nodeInfo{
    var node: SKSpriteNode
    var bornPos: CGPoint
    var dropped = false
}

class combatScene: SKScene{
    var identity: String!
    
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    
    var nodesInfo: Dictionary<String, nodeInfo> = Dictionary<String, nodeInfo>()
    var nodes: [SKSpriteNode] = []
    var peerList: [String] = []
    
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    
    var margin: CGFloat!
    
    func reScale(node: SKSpriteNode){
        node.setScale(1)
    }
    
    func randomPos() -> CGPoint{
        return CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 200, max: size.height - 2 * margin - 200))
    }
    
    func checkDrop(){
        var currentNode: SKSpriteNode
        for (name, info) in nodesInfo{
            currentNode = info.node
            if info.dropped == false{
                enumerateChildNodesWithName("hole"){node, _ in
                    if self.circleIntersection(node.position, center2: currentNode.position, radius1: 5, radius2: 25){
                        self.nodesInfo.updateValue(nodeInfo(node: currentNode, bornPos: info.bornPos, dropped: true), forKey: name)
                        currentNode.runAction(self.dropAnimation(currentNode, pos: info.bornPos))
                    }
                }
            }
        }
    }
    
    func dropAnimation(node: SKSpriteNode, pos: CGPoint) -> SKAction {
        return SKAction.sequence([SKAction.scaleTo(0, duration: 0.1),
            SKAction.waitForDuration(0.3),
            SKAction.runBlock(){
                self.reScale(node)
                node.position = pos
                node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                self.nodesInfo.updateValue(nodeInfo(node: node, bornPos: pos, dropped: false), forKey: node.name!)
            }])
    }
    
    func circleIntersection(center1: CGPoint, center2: CGPoint, radius1: CGFloat, radius2: CGFloat) -> Bool{
        if sqrt(pow(center1.x - center2.x, 2.0) + pow(center1.y - center2.y, 2.0)) < radius1 + radius2{
            return true
        }
        return false
    }
    
    func updatePeers(data: NSData, peer: String){}
    
    func addPlayer(data: NSData, peer: String){}
}
