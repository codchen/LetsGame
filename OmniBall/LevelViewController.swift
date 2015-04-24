//
//  LevelViewController.swift
//  OmniBall
//
//  Created by Fang on 3/14/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class LevelViewController: UIViewController {
    
    var gameViewController: GameViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
//        scrollController = self.storyboard?.instantiateViewControllerWithIdentifier("MinimapController") as MinimapController
//        scrollController.view.frame = CGRectMake(0, 75, 650, 650)
//        scrollController.gameViewController = gameViewController
//        addChildViewController(scrollController)
//        view.addSubview(scrollController.view)
    }
    
    @IBAction func mazeTransit(sender: AnyObject) {
        let mazeDifficultyController = self.storyboard?.instantiateViewControllerWithIdentifier("MazeDifficultyController") as MazeDifficultyController
        mazeDifficultyController.gameViewController = self.gameViewController
        self.presentViewController(mazeDifficultyController, animated: true, completion: nil)
    }
    
    @IBAction func arenaTransit(sender: AnyObject) {
        let arenaDifficultyController = self.storyboard?.instantiateViewControllerWithIdentifier("ArenaDifficultyController") as ArenaDifficultyController
        arenaDifficultyController.gameViewController = self.gameViewController
        self.presentViewController(arenaDifficultyController, animated: true, completion: nil)
    }


    @IBAction func back(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}