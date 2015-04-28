//
//  SceneToControllerAdapter.swift
//  OmniBall
//
//  Created by Fang on 4/8/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import UIKit

class SceneToControllerAdapter: NSObject {
    
    var controller: GameViewController!
    
    func setCurrentLevel(level: Int) {
        controller.currentLevel = level
    }
    
    func getCurrentLevel() -> Int {
        return controller.currentLevel
    }
    
    func transitToGame(gameMode: GameMode, gameState: GameState) {
        dispatch_async(dispatch_get_main_queue()){
            self.controller.transitToGame(gameMode, gameState: gameState)
        }
    }
    
    func transitToHiveMaze() {
        dispatch_async(dispatch_get_main_queue()){
            self.controller.transitToHiveMaze()

        }
    }
    
    
    func presentViewController(viewControllerToPresent: UIViewController, animated: Bool, completion: (()->Void)?) {
        dispatch_async(dispatch_get_main_queue()){
            self.controller.presentViewController(viewControllerToPresent, animated: animated, completion: completion)
        }
    }
    
    
    func clearCurrentView() {
        controller.currentView = nil
    }
    
}
