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
    var controller: DifficultyController!
    var connection: ConnectionManager!
    var currentLevel = 0
    
    init(size: CGSize, won: Bool) {
        self.won = won
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        connection = controller.connectionManager
        connection.gameState = .Done
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        AddChild(background)
        
        var label: SKSpriteNode!
        if won {
            label = SKSpriteNode(imageNamed: "700x200_you_win")
        } else {
            label = SKSpriteNode(imageNamed: "700x200_you_lose")
        }
        label.setScale(2.0)
        label.position = CGPointMake(size.width/2, size.height/2)
        AddChild(label)
        
        let wait = SKAction.waitForDuration(1)
        let block = SKAction.runBlock {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let myScene = LeaderBoardScene(size: self.size)
            switch self.connection.gameMode {
            case .BattleArena:
                myScene.gameType = "BattleArena"
            case .HiveMaze:
                myScene.gameType = "HiveMaze"
            case .PoolArena:
                myScene.gameType = "PoolArena"
            case .HiveMaze2:
                myScene.gameType = "HiveMaze2"
            default:
                return
            }
            myScene.scaleMode = self.scaleMode
            myScene.connection = self.connection
            myScene.controller = self.controller
            self.view?.presentScene(myScene, transition: reveal)
        }
        self.runAction(SKAction.sequence([wait, block]))
        
    }

    override func className() -> String{
        return "GameOverScene"
    }
    
}