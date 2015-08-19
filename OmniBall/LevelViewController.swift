//
//  LevelViewController.swift
//  OmniBall
//
//  Created by Fang on 3/14/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

class LevelViewController: UIViewController {
    var player: AVAudioPlayer!
    var gameViewController: GameViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        player = gameViewController.player
//        scrollController = self.storyboard?.instantiateViewControllerWithIdentifier("MinimapController") as MinimapController
//        scrollController.view.frame = CGRectMake(0, 75, 650, 650)
//        scrollController.gameViewController = gameViewController
//        AddChildViewController(scrollController)
//        view.addSubview(scrollController.view)
    }
    
    @IBAction func mazeTransit(sender: AnyObject) {
        let mazeDifficultyController = self.storyboard?.instantiateViewControllerWithIdentifier("MazeDifficultyController") as! MazeDifficultyController
        mazeDifficultyController.gameViewController = self.gameViewController
        mazeDifficultyController.connectionManager = self.gameViewController.connectionManager
        mazeDifficultyController.connectionManager.diffController = mazeDifficultyController
        mazeDifficultyController.player = player
        self.presentViewController(mazeDifficultyController, animated: true, completion: nil)
    }
    
    @IBAction func arenaTransit(sender: AnyObject) {
        let arenaDifficultyController = self.storyboard?.instantiateViewControllerWithIdentifier("ArenaDifficultyController") as! ArenaDifficultyController
        arenaDifficultyController.gameViewController = self.gameViewController
        arenaDifficultyController.connectionManager = self.gameViewController.connectionManager
        arenaDifficultyController.connectionManager.diffController = arenaDifficultyController
        arenaDifficultyController.player = player
        self.presentViewController(arenaDifficultyController, animated: true, completion: nil)
    }


    @IBAction func back(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}