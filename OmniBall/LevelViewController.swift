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
    var scrollController: MinimapController!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollController = self.storyboard?.instantiateViewControllerWithIdentifier("MinimapController") as MinimapController
        scrollController.view.frame = CGRectMake(0, 70, 650, 650)
        scrollController.gameViewController = gameViewController
        addChildViewController(scrollController)
        view.addSubview(scrollController.view)
    }
    
    @IBAction func back(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}