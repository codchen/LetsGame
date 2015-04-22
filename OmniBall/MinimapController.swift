//
//  MinimapController.swift
//  OmniBall
//
//  Created by Xiaoyu Chen on 3/30/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import UIKit

class MinimapController: UIViewController {
    var gameViewController: GameViewController!
    @IBOutlet weak var scroller: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        scroller.scrollEnabled = true
        scroller.contentSize = CGSize(width: 4450, height: 300)
    }
    @IBAction func map0(sender: AnyObject) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("BattleArena")
    }
    @IBAction func map1(sender: AnyObject) {
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("HiveMaze")
    }
    @IBAction func map2(sender: AnyObject) {
        gameViewController.currentLevel = 0
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("HiveMaze")
    }
    @IBAction func map3(sender: AnyObject) {
        gameViewController.currentLevel = 1
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("HiveMaze")
    }
    @IBAction func map4(sender: AnyObject) {
        gameViewController.currentLevel = 2
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        gameViewController.transitToGame("HiveMaze")
    }
}