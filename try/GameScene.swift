//
//  GameScene.swift
//  RawGame
//
//  Created by Xiaoyu Chen on 1/6/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene{
    var motionManager: CMMotionManager!
    var connection: ConnectionManager!
    var dot: SKSpriteNode!
    var ball: SKSpriteNode!
    var hole: SKSpriteNode!
    var peers: Dictionary<String, (CGPoint, CGVector, Bool)> = Dictionary<String, (CGPoint, CGVector, Bool)>()
    let steerDeadZone = CGFloat(0.15)
    let maxSpeed = CGFloat(1000)
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    var counter: Int = 5
    
    
    override func didMoveToView(view: SKView) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        ball = childNodeWithName("ball") as SKSpriteNode
        ball.physicsBody = SKPhysicsBody(rectangleOfSize: ball.size)
        hole = childNodeWithName("blackHole") as SKSpriteNode
        hole.position = CGPointMake(size.width/2, size.height/2)
        hole.zPosition = -1
        dot = SKSpriteNode(imageNamed: "circle")
        dot.name = "dot" + connection.session.myPeerID.displayName
        dot.position = CGPoint(x: playableMargin/2, y: playableRect.height/2)
    	dot.physicsBody = SKPhysicsBody(circleOfRadius: dot.size.width/2)
        dot.physicsBody?.mass = 5
        addChild(dot)

        
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
//        physicsWorld.gravity = normalize98(CGVector(dx: motionManager.accelerometerData.acceleration.y, dy: -1 * motionManager.accelerometerData.acceleration.x))
        var rawInput = CGPoint(x: CGFloat(motionManager.accelerometerData.acceleration.y), y: CGFloat(-1 * motionManager.accelerometerData.acceleration.x))
        if fabs(rawInput.x) < steerDeadZone{
            rawInput.x = 0
        }
        if fabs(rawInput.y) < steerDeadZone{
            rawInput.y = 0
        }
        dot.physicsBody?.velocity = CGVector(dx: CGFloat(rawInput.x * maxSpeed), dy: CGFloat(rawInput.y * maxSpeed))
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        connection.sendMove(Float(dot.physicsBody!.velocity.dx), dy: Float(dot.physicsBody!.velocity.dy),
            posX: Float(dot.position.x), posY: Float(dot.position.y), rotate: Float(dot.zRotation))
        var writer = "sent pos \(dot.position) \(NSDate.timeIntervalSinceReferenceDate())"
		println(writer)
        updatePeers()
        moveFromAcceleration()
        
    }
    
    func updatePeers() {
        for peer in peers {
            let node = childNodeWithName(peer.0) as SKSpriteNode
            
            node.physicsBody?.velocity = peer.1.1
            node.runAction(SKAction.moveTo(peer.1.0, duration: dt))
            println("movedTo pos \(peer.1.0) \(NSDate.timeIntervalSinceReferenceDate())")
            peers.updateValue((peer.1.0, peer.1.1, true), forKey: peer.0)

        }
    }
    
    func updatePeerPos(posX: Float, posY: Float, dx: Float, dy: Float, rotation: Float, peer: SKNode) {
        
        let pos = CGPoint(x: CGFloat(posX), y: CGFloat(posY))
        let velocity = CGVector(dx: CGFloat(dx), dy: CGFloat(dy))
        let updated = false
        peers[peer.name!] = (pos, velocity, updated)
        
        println("received pos \(pos) \(NSDate.timeIntervalSinceReferenceDate())")
        
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
