//
//  ViewController.swift
//  OmniBall
//
//  Created by Fang on 3/11/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class ViewController: UIViewController {
    
    var currentView: SKView!
    
    @IBAction func showTutorial(sender: UIButton) {
        
        let scene = TutorialScene.unarchiveFromFile("Tutorial") as TutorialScene
        if self.currentView == nil {
            let skView = SKView(frame: self.view.frame)
            // Configure the view.
            self.view.addSubview(skView)
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsPhysics = true
            
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            skView.shouldCullNonVisibleNodes = false
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            self.currentView = skView
        }
        self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(1))
    }
}