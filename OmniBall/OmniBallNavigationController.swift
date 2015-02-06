//
//  OmniBallNavigationController.swift
//  OmniBall
//
//  Created by Jiafang Jiang on 2/5/15.
//  Copyright (c) 2015 OmniBallCorp. All rights reserved.
//

import Foundation
import UIKit

class OmniBallNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:
            Selector("showAuthenticationViewController"), name:
            PresentAuthenticationViewController, object: nil)
        
        GameKitHelper.sharedInstance.authenticateLocalPlayer()
        super.viewDidLoad()
    }
    
    func showAuthenticationViewController() {
        let gameKitHelper = GameKitHelper.sharedInstance
        
        if let authenticationViewController = gameKitHelper.authenticationViewController {
            topViewController.presentViewController(authenticationViewController, animated: true,
                completion: nil)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}