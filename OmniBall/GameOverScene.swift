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
    var controller: ViewController!
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
        connection.gameState = .WaitingForMatch
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        var label: SKSpriteNode!
        if won {
            label = SKSpriteNode(imageNamed: "You win!")
        } else {
            label = SKSpriteNode(imageNamed: "You lose!")
        }
        label.setScale(2.0)
        label.position = CGPointMake(size.width/2, size.height/2)
        addChild(label)
        
        restartBtn = SKSpriteNode(imageNamed: "restart")
        restartBtn.name = "restart"
        restartBtn.position = CGPoint(x: size.width - 500, y: 500)
        addChild(restartBtn)
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {

        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        if restartBtn.containsPoint(loc){
            if connection.gameState == .WaitingForMatch {
                connection.generateRandomNumber()
                let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                if connection.maxPlayer == 1 {
                    let scene = GameScene.unarchiveFromFile("Level" + String(currentLevel)) as GameScene
                    scene.scaleMode = .AspectFill
                    scene.connection = self.connection
                    self.view?.presentScene(scene, transition: reveal)
                    currentLevel = 0
                } else {
                    let scene = WaitingForGameStartScene(size: CGSize(width: 2048, height: 1536))
                    scene.scaleMode = self.scaleMode
                    self.view?.presentScene(scene, transition: reveal)
                }

                
            }
        }
        
    }

    override func className() -> String{
        return "GameOverScene"
    }
    
}