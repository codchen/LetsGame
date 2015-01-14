//
//  GameScene.swift
//  RawGame
//
//  Created by Xiaoyu Chen on 1/6/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import SpriteKit
import CoreMotion
import MultipeerConnectivity


class GameScene: SKScene{
    var motionManager: CMMotionManager!
    var session: MCSession!
    var dot: SKSpriteNode!
    let steerDeadZone = CGFloat(0.15)
    let maxSpeed = CGFloat(1000)
    
    override func didMoveToView(view: SKView) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        dot = childNodeWithName("dot") as SKSpriteNode
        dot.name = "dot" + session.myPeerID.displayName
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
        //let dot = childNodeWithName("dot") as SKSpriteNode
        dot.physicsBody?.velocity = CGVector(dx: CGFloat(rawInput.x * maxSpeed), dy: CGFloat(rawInput.y * maxSpeed))
    }
    
    override func update(currentTime: NSTimeInterval) {
//        if motionManager.accelerometerData != nil {
//            println("accelerometer[\(motionManager.accelerometerData.acceleration.x),\(motionManager.accelerometerData.acceleration.y),\(motionManager.accelerometerData.acceleration.z)]")
//        }
        var error : NSError?
        let peers = self.session.connectedPeers
        if peers.count != 0{
            self.session.sendData(NSKeyedArchiver.archivedDataWithRootObject(dot), toPeers: self.session.connectedPeers, withMode: MCSessionSendDataMode.Unreliable, error: &error)
            if error != nil {
                print("Error sending data: \(error?.localizedDescription)")
            }
        }
        moveFromAcceleration()
    }
    
}
