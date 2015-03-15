//
//  WaitingForGameStartScene.swift
//  OmniBall
//
//  Created by Fang on 2/24/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class WaitingForGameStartScene: SKScene {
    
    var connection: ConnectionManager!
    var controller: GameViewController!
    
    override func didMoveToView(view: SKView) {
        view.backgroundColor = UIColor.blackColor()
        let waitingLabel = SKLabelNode(fontNamed:"Chalkduster")
        waitingLabel.text = "Waiting For Other Players"
        waitingLabel.fontSize = 120
        waitingLabel.fontColor = UIColor.whiteColor()
        waitingLabel.position =
            CGPoint(x: size.width/2, y: size.height/2)
        self.addChild(waitingLabel)
//        let scaleUpAction = SKAction.scaleTo(1.5, duration: 0.5);
//        let scaleDownAction = SKAction.scaleTo(0.5, duration: 0.5);
//        let scaleSequenceAction =
//        	SKAction.sequence([scaleUpAction,scaleDownAction])
//        let repeatForeverAction =
//        	SKAction.repeatActionForever(scaleSequenceAction)
//        waitingLabel.runAction(repeatForeverAction)
        let wait = SKAction.waitForDuration(1)
//        let block = SKAction.runBlock {
//            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//            if self.connection.playerID == 0 {
//                self.controller.transitToGame(CGPointZero, rotate: 1)
//            }
//        }
        self.runAction(wait)

    }
    
}