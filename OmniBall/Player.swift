//
//  Player.swift
//  OmniBall
//
//  Created by Fang on 2/19/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class Player: NSObject {
    
    var scene: GameScene!
    var players: [SKSpriteNode] = []
    var color: PlayerColors!
    var id: Int!
    var count: Int {
        get {
            return players.count
        }
    }
    
    func addPlayer(node: SKSpriteNode) {
        
    }
    
    func deletePlayer(index: Int) {
        
    }
    
    func setUpPlayers(playerColor: PlayerColors){
        
        var sprite: String!
        
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

}