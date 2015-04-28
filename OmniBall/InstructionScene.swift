//
//  InstructionScene.swift
//  OmniBall
//
//  Created by Fang on 3/14/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class InstructionScene: SKScene {
    var controller: GameViewController!
    var connection: ConnectionManager!
    var inTransit: Bool = false
    var animationOver: Bool = false
    
    override init(size: CGSize) {
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        var label: SKLabelNode!
        switch connection.gameMode {
        case .BattleArena:
            label = SKLabelNode(text: "Collect FIVE Stars to Win!")
        case .HiveMaze:
            label = SKLabelNode(text: "Collect Stars to Win!")
        default:
            return
        }
        
        
        label.fontName = "Chalkduster"
        label.fontSize = 120
        label.fontColor = UIColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        let wait = SKAction.waitForDuration(3)
        let block = SKAction.runBlock {
            if self.connection.gameState == GameState.WaitingForStart {
                self.controller.transitToGame(self.connection.gameMode, gameState: GameState.WaitingForStart)

            }
            self.animationOver = true
        }
        self.runAction(SKAction.sequence([wait, block]))
    }
    
    override func update(currentTime: NSTimeInterval) {
        if !inTransit && animationOver {
            if connection.gameState == GameState.WaitingForStart{
                inTransit = true
                self.controller.transitToGame(self.connection.gameMode, gameState: self.connection.gameState)
            }
        }

    }

}
