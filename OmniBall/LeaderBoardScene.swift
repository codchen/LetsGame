//
//  LeaderBoardScene.swift
//  OmniBall
//
//  Created by Fang on 3/11/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class PlayerScore: NSObject {
    let name: String
    let score: Int
    let id: UInt16
    init(name: String, score: Int, id: UInt16) {
        self.name = name
        self.score = score
        self.id = id
    }
}

class LeaderBoardScene: SKScene {
    
    var btnAgain: SKSpriteNode!
    var btnNext: SKSpriteNode!
//    var btnShow: SKLabelNode!
    var controller: DifficultyController!
    var connection: ConnectionManager!
    var currentLevel = 0
    var gameType: String!
    
    override init(size: CGSize) {
        super.init(size: size)
        self.size = size
    }

    required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        controller.currentLevel = 0
        connection.controller.currentLevel = 0
        connection = controller.connectionManager
        var startPos: CGFloat!
        if connection.gameMode == .HiveMaze || connection.gameMode == .PoolArena{
        	startPos = 200
        } else {
            startPos = 500
        }
        connection.gameState = .InLevelViewController
        self.connection.gameMode = .None
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        let leaderBoard = SKSpriteNode(imageNamed: "600x200_leaderboard")
        leaderBoard.position = CGPoint(x: size.width/2, y: size.height - 350)
        leaderBoard.setScale(2.0)
        addChild(leaderBoard)
        
        let lblRank = SKLabelNode(text: "Rank")
        lblRank.fontName = "Chalkduster"
        lblRank.fontSize = 60
        lblRank.position = CGPoint(x: startPos, y: size.height - 600)
        addChild(lblRank)
    
        let lblPlayer = SKLabelNode(text: "Player")
        lblPlayer.fontName = "Chalkduster"
        lblPlayer.fontSize = 60
        lblPlayer.position = CGPoint(x: startPos + 500, y: size.height - 600)
        addChild(lblPlayer)
        
        let lblScore = SKLabelNode(text: "Score")
        lblScore.fontName = "Chalkduster"
        lblScore.fontSize = 60
        lblScore.position = CGPoint(x: startPos + 1000, y: size.height - 600)
        lblScore.horizontalAlignmentMode = .Left
        addChild(lblScore)
        
        let peers = connection.peersInGame.peers
        let sortedScore: NSMutableArray = NSMutableArray(array: peers)
        let sortByScore = NSSortDescriptor(key: "score", ascending: false)
        let sortDescriptors = [sortByScore]
        sortedScore.sortUsingDescriptors(sortDescriptors)
        var peerScore = NSArray(array: sortedScore) as [Peer]
        
        for var index = 0; index < peerScore.count; ++index {
            let player = peerScore[index]
            let rank = SKLabelNode(text: String(index + 1))
            rank.fontName = "Chalkduster"
            rank.fontSize = 60
            rank.position = CGPoint(x: lblRank.position.x, y: lblRank.position.y - CGFloat(index + 1) * 100)
            addChild(rank)
            let name = SKLabelNode(text: player.getName())
            name.fontName = "Chalkduster"
            name.fontSize = 60
            name.position = CGPoint(x: lblPlayer.position.x,
                y: lblPlayer.position.y - CGFloat(index + 1) * 100)
            name.horizontalAlignmentMode = .Center
            addChild(name)
            for var star = 0; star < player.score; ++star {
                let icnStar = SKSpriteNode(imageNamed: getSlaveImageName(PlayerColors(rawValue: Int(player.playerID))!, false))
                icnStar.size = CGSize(width: icnStar.size.width * 0.6, height: icnStar.size.height * 0.6)
                icnStar.position = CGPoint(x: lblScore.position.x + CGFloat(star) * (icnStar.size.width), y: lblScore.position.y - CGFloat(index + 1) * 100)
                addChild(icnStar)
            }
        }
        
        btnNext = SKSpriteNode(imageNamed: "200x200_button_next")
        btnNext.position = CGPoint(x: size.width - 300, y: 400)
        addChild(btnNext)
        
        if (connection.me.playerID == 0 && connection.peersInGame.getNumPlayers() == connection.peersInGame.numOfPlayers) {
            btnAgain = SKSpriteNode(imageNamed: "200x200_button_replay")
            btnAgain.position = CGPoint(x: size.width - 500, y: 400)
            addChild(btnAgain)
        }
        
        connection.gameOver()
    
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        
        if btnNext.containsPoint(loc) {
            UIView.transitionWithView(view!, duration: 0.5,
                options: UIViewAnimationOptions.TransitionFlipFromBottom,
                animations: {
                    self.view!.removeFromSuperview()
                    self.controller.clearCurrentView()
                }, completion: nil)
            if connection.peersInGame.numOfPlayers != connection.peersInGame.getNumPlayers() {
                connection.exitGame()
                self.connection.controller!.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
                self.connection.controller!.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
            }
        } else if btnAgain != nil {
            if btnAgain.containsPoint(loc) {
                self.controller.transitToGame(gameType)
            }
        }
        
    }
    
    override func className() -> String{
        return "LeaderBoardScene"
    }
    
    deinit {
        println("LEADERBOARD DEINIT")
    }
    
}