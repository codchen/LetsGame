//
//  TutorialOverScene.swift
//  OmniBall
//
//  Created by Fang on 3/12/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class TutorialOverScene: SKScene {
    
    var btnAgain: SKSpriteNode!
    var btnNext: SKSpriteNode!
    var controller: ViewController!
    
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
        
        var label = SKSpriteNode(imageNamed: "700x200_you_win")
        label.setScale(2.0)
        label.position = CGPointMake(size.width/2, size.height/2)
        addChild(label)
        
        btnNext = SKSpriteNode(imageNamed: "200x200_button_next")
        btnNext.position = CGPoint(x: size.width - 300, y: 400)
        addChild(btnNext)
        
        btnAgain = SKSpriteNode(imageNamed: "200x200_button_replay")
        btnAgain.position = CGPoint(x: size.width - 500, y: 400)
        addChild(btnAgain)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        if btnNext.containsPoint(loc) {
            UIView.transitionWithView(view!, duration: 0.5,
                options: UIViewAnimationOptions.TransitionFlipFromBottom,
                animations: {
            		self.view!.removeFromSuperview()
                    self.controller.currentView = nil
            	}, completion: nil)
        } else if btnAgain.containsPoint(loc) {
            let scene = TutorialScene.unarchiveFromFile("Tutorial") as TutorialScene
            scene.vcontroller = controller
            scene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(scene, transition: reveal)
        }
    }
}