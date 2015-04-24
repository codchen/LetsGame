//
//  mazeDifficultyController.swift
//  OmniBall
//
//  Created by Xiaoyu Chen on 4/23/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class MazeDifficultyController: UIViewController {
    
    var gameViewController: GameViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func easy(sender: AnyObject) {
        gameViewController.transitToGame("HiveMaze")
        //self.presentingViewController!.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func hard(sender: AnyObject) {
        gameViewController.transitToGame("HiveMaze2")
        //self.presentingViewController!.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func back(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}