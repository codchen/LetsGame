//
//  GameOverScene.swift
//  try
//
//  Created by Jiafang Jiang on 1/30/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    let won: Bool
    var restartBtn: SKSpriteNode!
    var nextLevelBtn: SKSpriteNode!
    var _scene2modelAdptr: SceneToModelAdapter!
    var _scene2controllerAdptr: SceneToControllerAdapter!
//    var controller: GameViewController!
//    var connection: ConnectionManager!
    var currentLevel = 0
    
    init(size: CGSize, won: Bool) {
        self.won = won
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        _scene2modelAdptr.setGameState(GameState.WaitingForStart)
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        var label: SKSpriteNode!
        if won {
            label = SKSpriteNode(imageNamed: "700x200_you_win")
        } else {
            label = SKSpriteNode(imageNamed: "700x200_you_lose")
        }
        label.setScale(2.0)
        label.position = CGPointMake(size.width/2, size.height/2)
        addChild(label)
        
        let wait = SKAction.waitForDuration(1)
        let block = SKAction.runBlock {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let myScene = LeaderBoardScene(size: self.size)
            myScene.scaleMode = self.scaleMode
            myScene._scene2controllerAdptr = self._scene2controllerAdptr
            myScene._scene2modelAdptr = self._scene2modelAdptr
            self.view?.presentScene(myScene, transition: reveal)
            NSLog("Leaderboard scene opened")
        }
        self.runAction(SKAction.sequence([wait, block]))
        
    }

    override func className() -> String{
        return "GameOverScene"
    }
    
}