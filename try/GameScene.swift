//
//  GameScene.swift
//  TestForCollision
//
//  Created by Xiaoyu Chen on 2/2/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity
import CoreMotion

struct nodeInfo {
    var x: CGFloat
    var y: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var dt: CGFloat
    var index: UInt16
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var margin: CGFloat!
    
    var myNodes: [SKSpriteNode] = []
    var selected: Bool = false
    var locked: Bool = false
    var selectedNode: SKSpriteNode!
    
    var opponents: [SKSpriteNode] = []
    var opponentsUpdated: [Bool] = []
    var opponentsInfo: [nodeInfo] = []
    var count: UInt16 = 0
    
    var session: MCSession!
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    var currentTime: NSDate!
    
    var c: UInt32 = 0
    var lastCount: UInt32 = 0
    
    //node info
    var currentInfo: nodeInfo!
    var offset: CGFloat!
    
    //physics constants
    let maxSpeed = 600
    
    //hard coded!!
    let latency = 0.17
    
    func setUpLives() {
        
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        enumerateChildNodesWithName("node1"){node, _ in
            var node1 = node as SKSpriteNode
            node.physicsBody?.linearDamping = 0
            node.physicsBody?.restitution = 0.8
            self.myNodes.append(node1)
        }
        
        enumerateChildNodesWithName("node2"){node, _ in
            var node2 = node as SKSpriteNode
            node.physicsBody?.linearDamping = 0
            node.physicsBody?.restitution = 0.8
            self.opponents.append(node2)
            self.opponentsUpdated.append(false)
            self.opponentsInfo.append(nodeInfo(x: node.position.x, y: node.position.y, dx: 0, dy: 0, dt: 0, index: self.count))
            self.count++
        }
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
    }
    
    func randomPos() -> CGPoint{
        return CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 200, max: size.height - 2 * margin - 200))
    }
    
    func closeEnough(point1: CGPoint, point2: CGPoint) -> Bool{
        offset = point1.distanceTo(point2)
        if offset >= 10{
            return false
        }
        return true
    }
    
    func update_peer_dead_reckoning(){
        for index in 0...(opponents.count-1){
            if opponentsUpdated[index] == true{
                currentInfo = opponentsInfo[index]
                //opponents[index].physicsBody!.velocity = CGVector(dx: currentInfo.dx, dy: currentInfo.dy)
                if closeEnough(CGPoint(x: currentInfo.x, y: currentInfo.y), point2: opponents[index].position) == true{
                    opponents[index].physicsBody!.velocity = CGVector(dx: currentInfo.dx, dy: currentInfo.dy)
                }
                else{
                    opponents[index].physicsBody!.velocity = CGVector(dx: currentInfo.dx + (currentInfo.x - opponents[index].position.x), dy: currentInfo.dy + (currentInfo.y - opponents[index].position.y))
                }
                opponentsUpdated[index] = false
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
    }
    
    override func didEvaluateActions() {
        update_peer_dead_reckoning()
    }
    
    override func didSimulatePhysics() {
        sendMove()
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        //node1.physicsBody?.applyForce(CGVector(dx: -50, dy: 0))
        if locked == false{
            let touch = touches.anyObject() as UITouch
            let loc = touch.locationInNode(self)
            if selected == false{
                for node in myNodes{
                    if node.containsPoint(loc){
                        selectedNode = node
                        selectedNode.texture = SKTexture(imageNamed: "50x50_ball_selected")
                        //selectedNode.texture = SKTexture(imageNamed: "circle_selected")
                        selected = true
                        break
                    }
                }
            }
            else {
                selectedNode.physicsBody?.velocity = CGVector(dx: loc.x - selectedNode.position.x, dy: loc.y - selectedNode.position.y)
                selected = false
                selectedNode.texture = SKTexture(imageNamed: "50x50_ball")
                //selectedNode.texture = SKTexture(imageNamed: "circle")
                selectedNode = nil
                //locked = true
                sendMove()
            }
        }
    }
    
    func updatePeerPos(message: MessageMove) {
        self.currentTime = NSDate()
        if (message.count > lastCount){
            lastCount = message.count
            opponentsInfo[Int(message.index)] = nodeInfo(x: CGFloat(message.x), y: CGFloat(message.y), dx: CGFloat(message.dx), dy: CGFloat(message.dy), dt: CGFloat(message.dt), index: message.index)
            opponentsUpdated[Int(message.index)] = true
                
        }
    }
    
    func sendMove(){
        if session.connectedPeers.count >= 1{
            for index in 0...(myNodes.count-1){
                
                connection.sendMove(Float(myNodes[index].position.x), y: Float(myNodes[index].position.y), dx: Float(myNodes[index].physicsBody!.velocity.dx), dy: Float(myNodes[index].physicsBody!.velocity.dy), count: c, index: UInt16(index), dt: NSDate().timeIntervalSince1970)
                c++
            }
        }
    }
}
