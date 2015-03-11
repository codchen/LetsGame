//
//  LeaderBoardScene.swift
//  OmniBall
//
//  Created by Fang on 3/11/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class LeaderBoardScene: SKScene {
    
    var restartBtn: SKSpriteNode!
    var nextLevelBtn: SKSpriteNode!
    var controller: ViewController!
    var connection: ConnectionManager!
    var currentLevel = 0
    
    override init(size: CGSize) {
        super.init(size: size)
        self.size = size
    }

    required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        connection = controller.connectionManager
        connection.gameState = .WaitingForMatch
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        //        restartBtn = SKSpriteNode(imageNamed: "restart")
        //        restartBtn.name = "restart"
        //        restartBtn.position = CGPoint(x: size.width - 500, y: 500)
        //
        //        nextLevelBtn = SKSpriteNode(imageNamed: "circle")
        //        nextLevelBtn.setScale(2.0)
        //        nextLevelBtn.name = "nextLevel"
        //        nextLevelBtn.position = CGPoint(x: size.width - 800, y: 500)
        //
        //        addChild(restartBtn)
        //        addChild(nextLevelBtn)
        
        let wait = SKAction.waitForDuration(3.0)
        let block = SKAction.runBlock {
            //            let myScene = GameScene.unarchiveFromFile("Level" + String(self.currentLevel)) as GameScene
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            if self.connection.playerID == 0 {
                let myScene = GameScene.unarchiveFromFile("LevelTraining") as GameScene
                myScene.scaleMode = self.scaleMode
                myScene.connection = self.connection
                self.view?.presentScene(myScene, transition: reveal)
            } else {
                let scene = WaitingForGameStartScene(size: CGSize(width: 2048, height: 1536))
                scene.scaleMode = self.scaleMode
                self.view?.presentScene(scene, transition: reveal)
            }
        }
        self.runAction(SKAction.sequence([wait, block]))
        
        
    }
    
    override func className() -> String{
        return "LeaderBoardScene"
    }
    
}