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
    
    @IBAction func showBattleArena(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("BattleArena")
        
    }
    
    @IBAction func showHiveMaze(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("HiveMaze")
    }
    
}