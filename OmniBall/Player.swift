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
    
}

class Player: NSObject {
    
    var scene: GameScene!
    var players: [SKSpriteNode] = []
    var color: PlayerColors!
    var id: UInt16!
    var sprite: String!
    var count: Int {
        get {
            return players.count
        }
    }
    //hardcoded
    var capturedIndex = [-1, -1, -1]
//    var slaves: Dictionary<Int, SKSpriteNode> = Dictionary<Int, SKSpriteNode>()
    
    func addPlayer(node: SKSpriteNode) {
        
    }
    
    func deletePlayer(index: Int) {
        
    }
    
    func checkDead(){
        
    }
    
    func setUpPlayers(playerColor: PlayerColors){
        
        switch playerColor {
        case .Green:
            sprite = "node1"
        case .Red:
            sprite = "node2"
        case .Yellow:
            sprite = "node3"
        default:
            println("error in setup player color")
        }
        
        var node1: SKSpriteNode!
        var count: UInt16 = 0
        
        scene.enumerateChildNodesWithName(sprite){node, _ in
            node1 = node as SKSpriteNode
            node1.physicsBody = SKPhysicsBody(circleOfRadius: node1.size.width / 2 - 10)
            node1.physicsBody?.linearDamping = 0
            node1.physicsBody?.restitution = 1
            self.addPlayer(node1)
        }
        setMasks()
    }
    
    func setMasks(){
        
    }
    
    func getPlayerImageName(playerColor: PlayerColors, isSelected: Bool) -> String {
        if !isSelected {
            switch playerColor {
            case .Green:
                return "80x80_green_ball"
            case .Red:
                return "80x80_red_ball"
            case .Yellow:
                return "80x80_yellow_ball"
            case .Blue:
                return "80x80_blue_ball"
            }
        } else {
            switch playerColor {
            case .Green:
                return "80x80_green"
            case .Red:
                return "80x80_red"
            case .Yellow:
                return "80x80_yellow"
            case .Blue:
                return "80x80_blue_ball"
            }
        }
    }
    
    func updateCaptured(message: MessageCapture) {
        
    }
    
    func capture(index: Int, target: SKSpriteNode){
//        scene.lastCaptured[index] = NSDate().timeIntervalSince1970
        println("capture")
        for i in capturedIndex{
            println(i)
        }
        for player in players{
            println(player.name)
        }
        if capturedIndex[index] == -1{
        capturedIndex[index] = count
            addPlayer(target)}
//        slaves[index] = target
        target.texture = SKTexture(imageNamed: getPlayerImageName(color!, isSelected: false))
    }
    

    func decapture(index: Int){
//        slaves.removeValueForKey(index)
//        println("decapture")
//        for i in capturedIndex{
//            println(i)
//        }
//        for player in players{
//            println(player.name)
//        }
        if capturedIndex[index] != -1 {
            println("Delete Neutral at index \(capturedIndex[index])")
            deletePlayer(capturedIndex[index])
            capturedIndex[index] = -1
        }
    }
}