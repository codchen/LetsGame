//
//  PresentScene.swift
//  OmniBall
//
//  Created by Xiaoyu Chen on 3/16/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class PresentScene: SKScene{
    var currentLevel = 2
    var controller: DifficultyController!
    let btnNext = SKLabelNode(text: "Next")
    override func didMoveToView(view: SKView) {
        size = CGSize(width: 2048*4, height: 1536*4)
        anchorPoint = CGPoint(x: 3 / 8.0, y: 3 / 8.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        btnNext.position = CGPoint(x: (1 - anchorPoint.x) * size.width - 1000, y: (-anchorPoint.y) * size.height + 900)
        btnNext.fontSize = 512
        AddChild(btnNext)
    }
    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        if btnNext.containsPoint(loc){
            if currentLevel < 5{
                let nextScene = PresentScene.unarchiveFromFilePresent("Level"+String(currentLevel + 1)) as PresentScene
                nextScene.currentLevel = currentLevel + 1
                nextScene.controller = controller
                nextScene.scaleMode = scaleMode
                view!.presentScene(nextScene)
            }
            else{
                UIView.transitionWithView(view!, duration: 0.5,
                    options: UIViewAnimationOptions.TransitionFlipFromBottom,
                    animations: {
                        self.view!.removeFromSuperview()
                        self.controller.currentView = nil
                    }, completion: nil)
            }
        }
    }
}