//
//  RoundXScene.swift
//  OmniBall
//
//  Created by Fang on 3/12/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class RoundXScene: SKScene {
    
    var controller: GameViewController!
    var connection: ConnectionManager!
    var roundNum: Int!
    
    init(size: CGSize, roundNum: Int) {
        super.init(size: size)
        self.roundNum = roundNum
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
        if roundNum < connection.maxRoundNum {
            label = SKLabelNode(text: "Round: " + String(roundNum))
        } else if roundNum == connection.maxRoundNum {
            label = SKLabelNode(text: "Final Round")
        }

        label.fontName = "Chalkduster"
        label.fontSize = 200
        label.fontColor = UIColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        let wait = SKAction.waitForDuration(1)
        let block = SKAction.runBlock {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            if self.connection.playerID == 0 {
//                self.controller.transitToGame(CGPointZero, rotate: 1)
            }
        }
        self.runAction(SKAction.sequence([wait, block]))
    }
    
}
