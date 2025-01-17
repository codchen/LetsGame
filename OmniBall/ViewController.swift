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
        
        let scene = TutorialScene.unarchiveFromFile("Tutorial") as! TutorialScene
        if self.currentView == nil {
            let skView = SKView(frame: self.view.frame)
            // Configure the view.
            self.view.addSubview(skView)
            skView.showsFPS = false
            skView.showsNodeCount = false
            skView.showsPhysics = false
            
            scene.vcontroller = self
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = false
            skView.shouldCullNonVisibleNodes = false
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            self.currentView = skView
        }
        self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(1))
    }
    
    @IBAction func onePlayer(sender: AnyObject) {
        let gameViewController: GameViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
        gameViewController.playerNum = 1
        self.presentViewController(gameViewController, animated: true, completion: nil)
    }
    @IBAction func threePlayer(sender: AnyObject) {
        let gameViewController: GameViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
        gameViewController.playerNum = 3
        self.presentViewController(gameViewController, animated: true, completion: nil)
    }
    @IBAction func showGVC(sender: UIButton) {
    	let gameViewController: GameViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GameViewController") as! GameViewController
        gameViewController.playerNum = 2
        self.presentViewController(gameViewController, animated: true, completion: nil)
//        self.dismissViewControllerAnimated(true, completion: nil)

    }
    
    
}