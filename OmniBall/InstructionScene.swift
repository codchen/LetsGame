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
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//            self.controller.transitToGame(self.connection.gameMode, gameState: GameState.WaitingForStart)
            switch self.connection.gameMode {
            case .BattleArena:
                if self.connection.me.playerID == 0{
                    self.controller.transitToBattleArena(destination: CGPointZero, rotate: 1, starPos:CGPointZero)
                }
            case .HiveMaze:
                let levelScene = LevelXScene(size: self.size, level: self.controller.currentLevel + 1)
                levelScene.scaleMode = self.scaleMode
                levelScene._scene2controllerAdptr = SceneToControllerAdapter()
                levelScene._scene2controllerAdptr.controller = self.controller
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                self.view!.presentScene(levelScene, transition: reveal)
            default:
                return
            }
            
        }
        self.runAction(SKAction.sequence([wait, block]))
    }

}
