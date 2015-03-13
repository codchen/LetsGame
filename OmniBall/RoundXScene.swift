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
        let label = SKLabelNode(text: "Round: " + String(roundNum))
        label.fontName = "Chalkduster"
        label.fontSize = 200
        label.fontColor = UIColor.whiteColor()
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        let wait = SKAction.waitForDuration(1)
        let block = SKAction.runBlock {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            if self.connection.playerID == 0 {
                let myScene = GameScene.unarchiveFromFile("LevelTraining") as GameScene
                myScene.scaleMode = self.scaleMode
                myScene.connection = self.connection
                self.view?.presentScene(myScene, transition: reveal)
            }
        }
        self.runAction(SKAction.sequence([wait, block]))
    }
    
}
