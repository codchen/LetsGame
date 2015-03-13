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
    var controller: GameViewController!
    var connection: ConnectionManager!
    var currentLevel = 0
    
    override init(size: CGSize) {
        super.init(size: size)
        self.size = size
    }

    required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        connection = controller.connectionManager
        connection.gameState = .WaitingForMatch
        
        let background = SKSpriteNode(color: UIColor.blackColor(), size: self.size)
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        addChild(background)
        
        let leaderBoard = SKSpriteNode(imageNamed: "600x200_leaderboard")
        leaderBoard.position = CGPoint(x: size.width/2, y: size.height - 350)
        leaderBoard.setScale(1.5)
        addChild(leaderBoard)
        
        let lblRank = SKLabelNode(text: "Rank")
        lblRank.fontName = "Chalkduster"
        lblRank.fontSize = 50
        lblRank.position = CGPoint(x: 500, y: size.height - 550)
        addChild(lblRank)
    
        let lblPlayer = SKLabelNode(text: "Player")
        lblPlayer.fontName = "Chalkduster"
        lblPlayer.fontSize = 50
        lblPlayer.position = CGPoint(x: 1000, y: size.height - 550)
        addChild(lblPlayer)
        
        let lblScore = SKLabelNode(text: "Score")
        lblScore.fontName = "Chalkduster"
        lblScore.fontSize = 50
        lblScore.position = CGPoint(x: 1500, y: size.height - 550)
        lblScore.horizontalAlignmentMode = .Left
        addChild(lblScore)
        
        
        var score: [PlayerScore] = []
        var myName = connection.peerID.displayName
        let myId = Int(connection.playerID)
        let myScore = connection.scoreBoard[myId]
        if myName.hasSuffix("'s iPhone") {
            for var index = 0; index < countElements(myName); ++index {
                let i = advance(myName.startIndex, index)
                if myName[i] == "'" {
                    myName = myName.substringToIndex(i)
                    break
                }
            }
        }

        score.append(PlayerScore(name: myName, score: myScore!, id: myId))
        
        for (mcId, playerId) in connection.peersInGame {
            var playerName = mcId.displayName
            if playerName.hasSuffix("'s iPhone") {
                for var index = 0; index < countElements(playerName); ++index {
                    let i = advance(playerName.startIndex, index)
                    if playerName[i] == "'" {
                        playerName = playerName.substringToIndex(i)
                        break
                    }
                }
            }
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
            rank.fontSize = 50
            rank.position = CGPoint(x: lblRank.position.x, y: lblRank.position.y - CGFloat(index + 1) * 75)
            addChild(rank)
            let name = SKLabelNode(text: player.name)
            name.fontName = "Chalkduster"
            name.fontSize = 50
            name.position = CGPoint(x: lblPlayer.position.x,
                y: lblPlayer.position.y - CGFloat(index + 1) * 75)
            name.horizontalAlignmentMode = .Center
//            name.verticalAlignmentMode = .Bottom
            addChild(name)
            for var star = 0; star < player.score; ++star {
                let icnStar = SKSpriteNode(imageNamed: getSlaveImageName(PlayerColors(rawValue: player.id)!, false))
                icnStar.position = CGPoint(x: lblScore.position.x + CGFloat(star) * (icnStar.size.width + 15), y: lblScore.position.y - CGFloat(index + 1) * 75)
                addChild(icnStar)
            }
        }
        
        connection.roundNum++
        
        if connection.roundNum <= connection.maxRoundNum {
            let wait = SKAction.waitForDuration(5.0)
            let block = SKAction.runBlock {
                self.controller.transitToRoundX(self.connection.roundNum)
                //        	let myScene = GameScene.unarchiveFromFile("Level" + String(self.currentLevel)) as GameScene
                //            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
                //            if self.connection.playerID == 0 {
                //                let myScene = GameScene.unarchiveFromFile("LevelTraining") as GameScene
                //                myScene.scaleMode = self.scaleMode
                //                myScene.connection = self.connection
                //                self.view?.presentScene(myScene, transition: reveal)
                //            }
            }
            self.runAction(SKAction.sequence([wait, block]))
        } else {
            
            btnNext = SKSpriteNode(imageNamed: "200x200_button_next")
            btnNext.position = CGPoint(x: size.width - 300, y: 400)
            addChild(btnNext)
            
            btnAgain = SKSpriteNode(imageNamed: "200x200_button_replay")
            btnAgain.position = CGPoint(x: size.width - 500, y: 400)
            addChild(btnAgain)
        }
    }
    
    override func className() -> String{
        return "LeaderBoardScene"
    }
    
}