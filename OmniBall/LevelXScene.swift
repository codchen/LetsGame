//
//  RoundXScene.swift
//  OmniBall
//
//  Created by Fang on 3/12/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class LevelXScene: SKScene {
    
    var controller: GameViewController!
    var connection: ConnectionManager!
    var level: Int!
    
    init(size: CGSize, level: Int) {
        super.init(size: size)
        self.level = level
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        var label: SKLabelNode = SKLabelNode(text: "Level: " + String(level))
        label.fontName = "Chalkduster"
        label.fontSize = 200
        label.fontColor = UIColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        let wait = SKAction.waitForDuration(1)
        let block = SKAction.runBlock {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            self.controller.currentLevel++
            self.controller.transitToHiveMaze()
        }
        self.runAction(SKAction.sequence([wait, block]))
    }
    
}
