//
//  GameScene.swift
//  RawGame
//
//  Created by Xiaoyu Chen on 1/6/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate{
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    var dot: SKSpriteNode!
    var bornPos: CGPoint!
    var ball: SKSpriteNode!
    var hole: SKSpriteNode!
    var peers: Dictionary<String, Array<ConnectionManager.MessageMove>> = Dictionary<String, Array<ConnectionManager.MessageMove>>()
    let steerDeadZone = CGFloat(0.15)
    let maxSpeed = CGFloat(1000)
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    var counter: Int = 5
    
    var margin: CGFloat!
    var dropped = false
    
    var hasContacted: Bool = false
	var collisionCounter: Int = 50
    
    
    override func didMoveToView(view: SKView) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        dot = childNodeWithName("ball") as SKSpriteNode
        dot.name = "dot" + connection.session.myPeerID.displayName
        dot.position = randomPos()
        bornPos = dot.position
    	dot.physicsBody = SKPhysicsBody(circleOfRadius: dot.size.width/2)
        dot.physicsBody?.categoryBitMask = UInt32(1)
        
    }
    
    func normalize98(raw: CGVector) -> CGVector{
        var sign1, sign2: Int
        if raw.dx < 0{
            sign1 = -1
        }
        else{
            sign1 = 1
        }
        if raw.dy < 0{
            sign2 = -1
        }
        else{
            sign2 = 1
        }
        let tan = raw.dx / raw.dy
        let deltay = sqrt(9.8 / (1 + tan * tan))
        let deltax = fabs(tan * deltay)
        return CGVector(dx: CGFloat(sign1) * deltax, dy: CGFloat(sign2) * deltay)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask + contact.bodyB.categoryBitMask == 2 {
            hasContacted = true
        }
    }
    
    func moveFromAcceleration(){
        if motionManager.accelerometerData == nil{
            return
        }
        
        var accel2D = CGPointZero
        accel2D.x = CGFloat(motionManager.accelerometerData.acceleration.y)
        accel2D.y = -1 * CGFloat(motionManager.accelerometerData.acceleration.x)
//        accel2D.normalize()
        
        if fabs(accel2D.x) < steerDeadZone{
            accel2D.x = 0
        }
        if fabs(accel2D.y) < steerDeadZone{
            accel2D.y = 0
        }
        
        if hasContacted {
//            dot.physicsBody?.velocity = CGVector(dx: accel2D.x * maxSpeed, dy: accel2D.y * maxSpeed)
            counter--
            if counter == 0 {
                hasContacted = false
                counter = 50
            }
        }
        else if accel2D.x != 0 || accel2D.y != 0{
            dot.physicsBody?.velocity = CGVector(dx: CGFloat(accel2D.x * maxSpeed), dy: CGFloat(accel2D.y * maxSpeed))
        }
    }
    
    func checkDrop(){
        enumerateChildNodesWithName("hole"){node, _ in
            if self.circleIntersection(node.position, center2: self.dot.position, radius1: 5, radius2: 25){
                self.dropped = true
                self.dot.runAction(SKAction.sequence([SKAction.scaleTo(0, duration: 0.1),
                                                        SKAction.waitForDuration(0.3),
                                                        SKAction.runBlock(){
                                                            self.reScale()
                                                            self.dot.position = self.randomPos()
                                                            println(self.dot.position)
                                                            self.dot.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                                                            self.dropped = false
                                                        }]))
            }
        }
    }
    
    func reScale(){
        dot.setScale(1)
    }
    
    func randomPos() -> CGPoint{
        return CGPoint(x: CGFloat.random(min: 200, max: size.width - 200), y: CGFloat.random(min: 0 + 200, max: size.height - 2 * margin - 200))
    }
    
    func circleIntersection(center1: CGPoint, center2: CGPoint, radius1: CGFloat, radius2: CGFloat) -> Bool{
        if sqrt(pow(center1.x - center2.x, 2.0) + pow(center1.y - center2.y, 2.0)) < radius1 + radius2{
            return true
        }
        return false
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        moveFromAcceleration()
        connection.sendMove(Float(dot.physicsBody!.velocity.dx), dy: Float(dot.physicsBody!.velocity.dy),
            posX: Float(dot.position.x), posY: Float(dot.position.y), rotate: Float(dot.zRotation), dt: Float(dt))
        println("Sent pos is \(dot.position)")
        updatePeers()
        if !dropped{
            checkDrop()
        }
        
        
    }
    
    func updatePeers() {
        for (peer, message) in peers {
            let node = childNodeWithName(peer.0) as SKSpriteNode
            if !message.isEmpty {
                var copyMes = message
                var update = copyMes.removeAtIndex(0)
                var newVel = CGVector(dx: CGFloat(update.dx), dy: CGFloat(update.dy))
                var newPos = CGPoint(x: CGFloat(update.posX), y: CGFloat(update.posY))
                node.physicsBody?.velocity = newVel
                node.zRotation = CGFloat(update.rotate)
                node.position = newPos
//                node.runAction(SKAction.moveTo(newPos, duration: NSTimeInterval(update.dt)))
                peers[peer] = copyMes
            }
        }
    }
    
    func updatePeerPos(message: ConnectionManager.MessageMove, peer: SKNode) {
        
        if peers[peer.name!] == nil {
            peers[peer.name!] = Array<ConnectionManager.MessageMove>()
        }
        println("Received pos is \(CGPoint(x:CGFloat(message.posX), y: CGFloat(message.posY)))")
        peers[peer.name!]?.append(message)
        
    }
    
    func addPlayer(posX: Float, posY: Float, name: String) {
        var peerDot = SKSpriteNode(imageNamed: "50x50_ball")
        peerDot.physicsBody = SKPhysicsBody(circleOfRadius: peerDot.size.width/2)
        peerDot.name = "dot" + name
        peerDot.position = CGPoint(x: CGFloat(posX), y: CGFloat(posY))
        peerDot.physicsBody?.categoryBitMask = UInt32(1)
        addChild(peerDot)
    }
    
}
