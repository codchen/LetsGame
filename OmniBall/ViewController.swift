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
        println("bibibibibibibibibi")
        if let scene = TutorialScene.unarchiveFromFile("Tutorial") as? TutorialScene {
            if self.currentView == nil {
                let skView = SKView(frame: self.view.frame)
                // Configure the view.
                self.view.addSubview(skView)
                skView.showsFPS = false
                skView.showsNodeCount = false
                skView.showsPhysics = false
                
                scene.controller = self
                
                /* Sprite Kit applies additional optimizations to improve rendering performance */
                skView.ignoresSiblingOrder = false
                skView.shouldCullNonVisibleNodes = false
                
                /* Set the scale mode to scale to fit the window */
                scene.scaleMode = .AspectFill
                
                self.currentView = skView
            }
            println("np1")
            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(1))
        }

    }
    
    @IBAction func showGVC(sender: UIButton) {
    	let gameViewController: GameViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GameViewController") as GameViewController
        self.presentViewController(gameViewController, animated: true, completion: nil)
        
    }
    
    func clearCurrentView() {
        self.currentView = nil
    }
    
    
}