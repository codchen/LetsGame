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
    var peers: Dictionary<String, (CGPoint, CGVector, Bool)> = Dictionary<String, (CGPoint, CGVector, Bool)>()
    let steerDeadZone = CGFloat(0.15)
    let maxSpeed = CGFloat(1000)
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    var counter: Int = 5
    
    var margin: CGFloat!
    var dropped = false
    
    let ay = Vector3(x: 0.63, y: 0.0, z: -0.92)
    let az = Vector3(x: 0.0, y: 1.0, z: 0.0)
    let ax = Vector3.crossProduct(Vector3(x: 0.0, y: 1.0, z: 0.0),
        right: Vector3(x: 0.63, y: 0.0, z: -0.92)).normalized()
    var hasContacted: Bool = false
    
    
    override func didMoveToView(view: SKView) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        //ball = childNodeWithName("ball") as SKSpriteNode
        //ball.physicsBody = SKPhysicsBody(rectangleOfSize: ball.size)
//        hole = childNodeWithName("hole") as SKSpriteNode
//        hole.position = CGPointMake(size.width/2, size.height/2)
        //hole.zPosition = -1
        dot = childNodeWithName("ball") as SKSpriteNode
        dot.name = "dot" + connection.session.myPeerID.displayName
        dot.position = randomPos()
        bornPos = dot.position
    	dot.physicsBody = SKPhysicsBody(circleOfRadius: dot.size.width/2)
//        dot.physicsBody?.mass = 5
        //addChild(dot)

        
//        connection.sendMove(Float(dot.physicsBody!.velocity.dx), dy: Float(dot.physicsBody!.velocity.dy),
//            posX: Float(dot.position.x), posY: Float(dot.position.y), rotate: Float(dot.zRotation))
//        println("Sent pos is: \(dot.position)")
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
    
    func moveFromAcceleration(){
        if motionManager.accelerometerData == nil{
            return
        }
        var raw = Vector3(
            x: CGFloat(motionManager.accelerometerData.acceleration.x),
            y: CGFloat(motionManager.accelerometerData.acceleration.y),
            z: CGFloat(motionManager.accelerometerData.acceleration.z))
        
        var accel2D = CGPointZero
        accel2D.x = Vector3.dotProduct(raw, right: az)
        accel2D.y = Vector3.dotProduct(raw, right: ax)
        accel2D.normalize()
        
        if fabs(accel2D.x) < steerDeadZone{
            accel2D.x = 0
        }
        if fabs(accel2D.y) < steerDeadZone{
            accel2D.y = 0
        }
        
        if hasContacted {
            dot.physicsBody?.velocity += CGVector(dx: CGFloat(accel2D.x * maxSpeed), dy: CGFloat(accel2D.y * maxSpeed))
            hasContacted = false
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
        
        if peers.count > 0{
            connection.sendMove(Float(dot.physicsBody!.velocity.dx), dy: Float(dot.physicsBody!.velocity.dy),
            posX: Float(dot.position.x), posY: Float(dot.position.y), rotate: Float(dot.zRotation))
        }
        var writer = "sent pos \(dot.position) \(NSDate.timeIntervalSinceReferenceDate())"
		//println(writer)
        updatePeers()
        if !dropped{
            checkDrop()
        }
        moveFromAcceleration()
        
    }
    
    func updatePeers() {
        for peer in peers {
            let node = childNodeWithName(peer.0) as SKSpriteNode
            
            //node.physicsBody?.velocity = peer.1.1
            node.runAction(SKAction.moveTo(peer.1.0, duration: dt))
            //println("movedTo pos \(peer.1.0) \(NSDate.timeIntervalSinceReferenceDate())")
            peers.updateValue((peer.1.0, peer.1.1, true), forKey: peer.0)

        }
    }
    
    func updatePeerPos(posX: Float, posY: Float, dx: Float, dy: Float, rotation: Float, peer: SKNode) {
        
        let pos = CGPoint(x: CGFloat(posX), y: CGFloat(posY))
        let velocity = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
        let updated = false
        peers[peer.name!] = (pos, velocity, updated)
        
        //println("received pos \(pos) \(NSDate.timeIntervalSinceReferenceDate())")
        
//        peer.physicsBody?.velocity = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
//        let newPos = CGPoint(x: CGFloat(posX), y: CGFloat(posY))
//        let time = newPos / peer.physicsBody!.velocity
//        peer.runAction(SKAction.moveTo(newPos, duration: NSTimeInterval(max(time.x, time.y))))
//        if rotation != 0 {
//            peer.zRotation = CGFloat(rotation)
//        }
    }
    
    func addPlayer(posX: Float, posY: Float, name: String) {
        var peerDot = SKSpriteNode(imageNamed: "circle")
        peerDot.physicsBody = SKPhysicsBody(circleOfRadius: peerDot.size.width/2)
        peerDot.name = "dot" + name
        peerDot.position.x = CGFloat(posX)
        peerDot.position.y = CGFloat(posY)
        addChild(peerDot)
//        connection.sendMove(Float(dot.physicsBody!.velocity.dx), dy: Float(dot.physicsBody!.velocity.dy),
//        	posX: Float(dot.position.x), posY: Float(dot.position.y), rotate: Float(dot.zRotation))
//        println("Sent pos is: \(dot.position)")
    }
    
}
