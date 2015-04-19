//
//  Player.swift
//  OmniBall
//
//  Created by Fang on 2/19/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

struct physicsCategory{
    
    static let None: UInt32 = 0
    static let Me: UInt32 = 0b1
    static let Opponent: UInt32 = 0b10
    static let target: UInt32 = 0b100
    static let wall: UInt32 = 0b1000
    
}

struct NeutralBall {
    let node: SKSpriteNode
    var lastCapture: NSTimeInterval
}

class Player: NSObject {
    
    var scene: GameScene!
    var players: [SKSpriteNode] = []
    var slaves: Dictionary<String, NeutralBall> = Dictionary<String, NeutralBall>()
    var bornPos: [CGPoint] = []
    var color: PlayerColors!
    var id: UInt16!
    var sprite: String!
    var count: Int {
        get {
            return players.count
        }
    }
    //hardcoded
//    var capturedIndex = [-1, -1, -1, -1]
//    var slaves: Dictionary<Int, SKSpriteNode> = Dictionary<Int, SKSpriteNode>()
    
    func addPlayer(node: SKSpriteNode) {
        
    }
    
    func deletePlayer(index: Int) {
        
    }
    
    func setUpPlayers(playerColor: PlayerColors){
        
        switch playerColor {
        case .Green:
            sprite = "node1"
        case .Red:
            sprite = "node2"
        case .Blue:
            sprite = "node3"
        default:
            println("error in setup player color")
        }
        
        var node1: SKSpriteNode!
        var count: UInt16 = 0
        
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node1 = node as! SKSpriteNode
            node1.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "80x80_blue_ball"), alphaThreshold: 0.99, size: CGSize(width: 150, height: 150))
            //node1.physicsBody = SKPhysicsBody(circleOfRadius: node1.size.width / 2 - 25)
            node1.physicsBody?.linearDamping = 0
            node1.physicsBody?.restitution = 1
            self.addPlayer(node1)
            self.bornPos.append(node1.position)
        }
        setMasks()
    }
    
    func setMasks(){
        
    }

    func capture(target: SKSpriteNode, capturedTime: NSTimeInterval){
        if (target.name!.hasPrefix("neutral") == false){
            return
        }
        if slaves[target.name!] == nil {
            target.physicsBody?.dynamic = true
            slaves[target.name!] = NeutralBall(node: target, lastCapture: capturedTime)
            target.texture = SKTexture(imageNamed: getSlaveImageName(color!, false))
        }
    }
    

    func decapture(target: SKSpriteNode){

    }
    
    func captureAnimation(target: SKSpriteNode, isOppo: Bool){
        let originalTexture = SKTexture(imageNamed: getSlaveImageName(color!, false))
        let changedTexture = SKTexture(imageNamed: getSlaveImageName(color!, true))
        let block1 = SKAction.runBlock {
            target.texture = originalTexture
        }
        let block2 = SKAction.runBlock {
            target.texture = changedTexture
        }
        let wait = SKAction.waitForDuration(0.23)
        var flashAction: SKAction!
        if isOppo {
            flashAction = SKAction.sequence([block2, wait, block1, wait])
        } else {
            flashAction = SKAction.sequence([block1, wait, block2, wait])
        }
        target.removeAllActions()
        target.runAction(SKAction.repeatAction(flashAction, count: 4))
    }
}