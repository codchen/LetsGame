//
//  DifficultyController.swift
//  OmniBall
//
//  Created by Xiaoyu Chen on 4/24/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class DifficultyController: UIViewController {
    var gameViewController: GameViewController!
    var currentView: SKView!
    var currentGameScene: GameScene!
    var connectionManager: ConnectionManager!
    var currentLevel = 0
    
    func transitToGame(name: String) {
        if connectionManager.gameState == .InLevelViewController {
            if name == "BattleArena"  {
                connectionManager.gameMode = .BattleArena
            } else if name == "HiveMaze" {
                connectionManager.gameMode = .HiveMaze
            } else if name == "PoolArena" {
                connectionManager.gameMode = .PoolArena
            } else if name == "HiveMaze2" {
                connectionManager.gameMode = .HiveMaze2
            }
            
            if self.connectionManager.peersInGame.getNumPlayers() == 1 {
                self.transitToInstruction()
            } else {
                connectionManager.sendGameStart()
                connectionManager.readyToSendFirstTrip()
            }
        }
    }
    
    func transitToWaitForGameStart(){
        dispatch_async(dispatch_get_main_queue()){
            let scene = WaitingForGameStartScene()
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            scene.controller = self
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
        }
    }
    
    func configureCurrentView(){
        let skView = SKView(frame: self.view.frame)
        // Configure the view.
        self.view.addSubview(skView)
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.showsPhysics = false
        skView.ignoresSiblingOrder = false
        skView.shouldCullNonVisibleNodes = false
        self.currentView = skView
        if (self.gameViewController != nil) {
            self.gameViewController.currentView = self.currentView
        }
    }
    
    func transitToInstruction(){
        dispatch_async(dispatch_get_main_queue()) {
            let scene = InstructionScene(size: CGSize(width: 2048, height: 1536))
            scene.scaleMode = .AspectFit
            scene.connection = self.connectionManager
            scene.controller = self
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentView.presentScene(scene, transition: SKTransition.flipHorizontalWithDuration(0.5))
        }
    }
    
    func transitToBattleArena(destination: CGPoint = CGPointZero, rotate: CGFloat = 1, starPos: CGPoint = CGPointZero){
        dispatch_async(dispatch_get_main_queue()) {
            if self.connectionManager.gameState == GameState.InGame {
                if destination != CGPointZero {
                    self.currentGameScene.updateDestination(destination, desRotation: rotate, starPos: starPos)
                }
            } else {
                let scene = GameBattleScene.unarchiveFromFile("LevelTraining") as GameBattleScene
                scene.scaleMode = .AspectFill
                scene.connection = self.connectionManager
                if self.currentView == nil {
                    self.configureCurrentView()
                }
                if destination != CGPointZero {
                    scene.destPos = destination
                    scene.destRotation = rotate
                    scene.neutralPos = starPos
                }
                self.currentGameScene = scene
                if (self.gameViewController != nil) {
                    self.gameViewController.currentGameScene = self.currentGameScene
                }
                scene.controller = self
                self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
            }
        }
    }
    
    func transitToHiveMaze(){
        dispatch_async(dispatch_get_main_queue()) {
            self.connectionManager.maxLevel = 4
            let scene = GameLevelScene.unarchiveFromFile("Level"+String(self.currentLevel)) as GameLevelScene
            scene.currentLevel = self.currentLevel
            scene.slaveNum = self.currentLevel
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentGameScene = scene
            if (self.gameViewController != nil) {
                self.gameViewController.currentGameScene = self.currentGameScene
            }
            scene.controller = self
            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
            
        }
    }
    
    func transitToHiveMaze2(){
        dispatch_async(dispatch_get_main_queue()) {
            self.connectionManager.maxLevel = 6
            let scene = GameLevelScene.unarchiveFromFile("HLevel"+String(self.currentLevel)) as GameLevelScene
            scene.currentLevel = self.currentLevel
            scene.slaveNum = self.currentLevel
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentGameScene = scene
            if (self.gameViewController != nil) {
                self.gameViewController.currentGameScene = self.currentGameScene
            }
            scene.controller = self
            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
            
        }
    }
    
    func transitToPoolArena() {
        dispatch_async(dispatch_get_main_queue()) {
            let scene = GamePoolScene.unarchiveFromFile("PoolArena") as GamePoolScene
            scene.slaveNum = 7
            scene.scaleMode = .AspectFill
            scene.connection = self.connectionManager
            if self.currentView == nil {
                self.configureCurrentView()
            }
            self.currentGameScene = scene
            if (self.gameViewController != nil) {
                self.gameViewController.currentGameScene = self.currentGameScene
            }
            scene.controller = self
            self.currentView.presentScene(self.currentGameScene, transition: SKTransition.flipHorizontalWithDuration(0.5))
        }
    }
    
    func clearCurrentView() {
        self.currentView = nil
        if (self.gameViewController != nil) {
            self.gameViewController.currentView = nil
        }
    }

}