//
//  DifficultyViewController.swift
//  OmniBall
//
//  Created by Xiaoyu Chen on 4/23/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class ArenaDifficultyController: UIViewController {
    
    var gameViewController: GameViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func easyBtn(sender: AnyObject) {
        gameViewController.transitToGame("BattleArena")
        //self.presentingViewController!.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func hardBtn(sender: AnyObject) {
        gameViewController.transitToGame("PoolArena")
        //self.presentingViewController!.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func backBtn(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
