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

enum PlayerColors: Int{
    case Green, Red, Yellow, Blue
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
    
    var playerColor: PlayerColors!
    
    override init() {
        connection.sendGameStart()
    }
    
    func setUpUI(playerColor: PlayerColors) {
        switch playerColor {
            case .Green
                setUpPlayers("node1", playerOpp: "node2")
            case .Red
                setUpPlayers("node2", playerOpp: "node1")
        }
    }
    
    func setUpPlayers(playerSelf: String, playerOpp: String){
        enumerateChildNodesWithName(playerSelf){node, _ in
            var node1 = node as SKSpriteNode
            node.physicsBody?.linearDamping = 0
            node.physicsBody?.restitution = 0.8
            self.myNodes.append(node1)
        }
        
        enumerateChildNodesWithName(playerOpp){node, _ in
            var node2 = node as SKSpriteNode
            node.physicsBody?.linearDamping = 0
            node.physicsBody?.restitution = 0.8
            self.opponents.append(node2)
            self.opponentsUpdated.append(false)
            self.opponentsInfo.append(nodeInfo(x: node.position.x, y: node.position.y, dx: 0, dy: 0, dt: 0, index: self.count))
            self.count++
        }
    }
    
    func getPlayerImageName(playerColor: PlayerColors, isSelected: Bool) -> String {
        if !isSelected {
            switch playerColor {
            case .Green
                return "80x80_green_ball"
            case .Red
                return "80x80_red_ball"
            case .Yellow
                return "80x80_yellow_ball"
            case .Blue
                return "80x80_blue_ball"
            }
        }
        
    }
    
    override func didMoveToView(view: SKView) {
        
        playerColor = PlayerColors(connection.playerID)
        setUpUI(playerColor)
        /* Setup your scene here */

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
        enumerateChildNodesWithName("hole"){hole, _ in
            for index in 0...(self.myNodes.count - 1){
                if self.myNodes[index].position.distanceTo(hole.position)<30{
                    self.myDeadNodes.insert(index, atIndex: 0)
                }
            }
            for index in self.myDeadNodes{
                self.deleteMyNode(index)
            }
        }
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
                selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(self.playerColor, isSelected: false))
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
