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
    let id: Int
    init(name: String, score: Int, id: Int) {
        self.name = name
        self.score = score
        self.id = id
    }
}

class LeaderBoardScene: SKScene {
    
    var btnAgain: SKSpriteNode!
    var btnNext: SKSpriteNode!
//    var btnShow: SKLabelNode!
    var controller: GameViewController!
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
        controller.currentLevel = -1
        connection = controller.connectionManager
        connection.gameState = .WaitingForStart
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
        lblRank.position = CGPoint(x: 500, y: size.height - 600)
        addChild(lblRank)
    
        let lblPlayer = SKLabelNode(text: "Player")
        lblPlayer.fontName = "Chalkduster"
        lblPlayer.fontSize = 60
        lblPlayer.position = CGPoint(x: 1000, y: size.height - 600)
        addChild(lblPlayer)
        
        let lblScore = SKLabelNode(text: "Score")
        lblScore.fontName = "Chalkduster"
        lblScore.fontSize = 60
        lblScore.position = CGPoint(x: 1500, y: size.height - 600)
        lblScore.horizontalAlignmentMode = .Left
        addChild(lblScore)
        
        
        var score: [PlayerScore] = []
        var myName = connection.peerID.displayName
        let myId = Int(connection.playerID)
        let myScore = connection.scoreBoard[myId]

        score.append(PlayerScore(name: myName, score: myScore!, id: myId))
        
        for (mcId, playerId) in connection.peersInGame {
            var playerName = mcId.displayName
            let playerScore = connection.scoreBoard[playerId]
            score.append(PlayerScore(name: playerName, score: playerScore!, id: playerId))
        }
        
        let sortedScore: NSMutableArray = NSMutableArray(array: score)
        let sortByScore = NSSortDescriptor(key: "score", ascending: false)
        let sortDescriptors = [sortByScore]
        sortedScore.sortUsingDescriptors(sortDescriptors)
        
        score = NSArray(array: sortedScore) as [PlayerScore]
        
        for var index = 0; index < score.count; ++index {
            let player = score[index]
            let rank = SKLabelNode(text: String(index + 1))
            rank.fontName = "Chalkduster"
            rank.fontSize = 60
            rank.position = CGPoint(x: lblRank.position.x, y: lblRank.position.y - CGFloat(index + 1) * 100)
            addChild(rank)
            let name = SKLabelNode(text: player.name)
            name.fontName = "Chalkduster"
            name.fontSize = 60
            name.position = CGPoint(x: lblPlayer.position.x,
                y: lblPlayer.position.y - CGFloat(index + 1) * 100)
            name.horizontalAlignmentMode = .Center
            addChild(name)
            for var star = 0; star < player.score; ++star {
                let icnStar = SKSpriteNode(imageNamed: getSlaveImageName(PlayerColors(rawValue: player.id)!, false))
                icnStar.position = CGPoint(x: lblScore.position.x + CGFloat(star) * (icnStar.size.width), y: lblScore.position.y - CGFloat(index + 1) * 100)
                addChild(icnStar)
            }
        }
        
        connection.gameOver()
        
        btnNext = SKSpriteNode(imageNamed: "200x200_button_next")
        btnNext.position = CGPoint(x: size.width - 300, y: 400)
        addChild(btnNext)
        
        btnAgain = SKSpriteNode(imageNamed: "200x200_button_replay")
        btnAgain.position = CGPoint(x: size.width - 500, y: 400)
        addChild(btnAgain)
        
//        btnShow = SKLabelNode(text: "Next")
//        btnShow.position = CGPoint(x: 500, y: 400)
//        addChild(btnShow)
        
//        connection.roundNum++
//        
//        if connection.roundNum <= connection.maxRoundNum {
//            let wait = SKAction.waitForDuration(4.0)
//            let block = SKAction.runBlock {
////                self.controller.transitToRoundX(self.connection.roundNum)
//            }
//            self.runAction(SKAction.sequence([wait, block]))
//        } else {
//            
//
//        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        if btnNext != nil && btnAgain != nil {
            if btnNext.containsPoint(loc) {
                UIView.transitionWithView(view!, duration: 0.5,
                    options: UIViewAnimationOptions.TransitionFlipFromBottom,
                    animations: {
                        self.view!.removeFromSuperview()
                        self.controller.currentView = nil
                    }, completion: nil)
            } else if btnAgain.containsPoint(loc) {
                if gameType == "BattleArena"{
                    self.connection.gameMode = .BattleArena
                }
                else if gameType == "HiveMaze"{
                    self.connection.gameMode = .HiveMaze
                    
                }
//                connection.generateRandomNumber()
//                controller.transitToRoundX(connection.roundNum)
            }
            
//            else if btnShow.containsPoint(loc) {
//                let scene = PresentScene.unarchiveFromFilePresent("Level2") as PresentScene
//                scene.controller = controller
//                scene.scaleMode = scaleMode
//                view!.presentScene(scene)
//            }
        }
    }
    
    override func className() -> String{
        return "LeaderBoardScene"
    }
    
}