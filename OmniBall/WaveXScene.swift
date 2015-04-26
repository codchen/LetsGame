//
//  WaveXScene.swift
//  OmniBall
//
//  Created by Xiaoyu Chen on 4/26/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class WaveXScene: SKScene {
    
    var controller: DifficultyController!
    var connection: ConnectionManager!
    var wave: Int!
    
    init(size: CGSize, wave: Int) {
        super.init(size: size)
        self.wave = wave
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        var label: SKLabelNode = SKLabelNode(text: "Wave " + String(level) + "!")
        label.fontName = "Chalkduster"
        label.fontSize = 200
        label.fontColor = UIColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        let wait = SKAction.waitForDuration(1)
        let block = SKAction.runBlock {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            self.controller.transitToPoolArena(wave)
        }
        self.runAction(SKAction.sequence([wait, block]))
    }
    
}
