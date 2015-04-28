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
    
    var _scene2modelAdptr: SceneToModelAdapter!
    var _scene2controllerAdptr: SceneToControllerAdapter!
//    var controller: GameViewController!
//    var connection: ConnectionManager!
    var currentLevel = 0
//    var gameType: String!
    
    override init(size: CGSize) {
        super.init(size: size)
        self.size = size
    }

    required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
    }
    
    override func didMoveToView(view: SKView) {
        _scene2controllerAdptr.setCurrentLevel(-1)
//        controller.currentLevel = -1
        _scene2modelAdptr.setGameState(GameState.WaitingForReconcil)
//        connection.gameState = .WaitingForStart
//        self.connection.gameMode = .None
        
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
        lblRank.position = CGPoint(x: 200, y: size.height - 600)
        addChild(lblRank)
    
        let lblPlayer = SKLabelNode(text: "Player")
        lblPlayer.fontName = "Chalkduster"
        lblPlayer.fontSize = 60
        lblPlayer.position = CGPoint(x: 700, y: size.height - 600)
        addChild(lblPlayer)
        
        let lblScore = SKLabelNode(text: "Score")
        lblScore.fontName = "Chalkduster"
        lblScore.fontSize = 60
        lblScore.position = CGPoint(x: 1200, y: size.height - 600)
        lblScore.horizontalAlignmentMode = .Left
        addChild(lblScore)
        
        
        let peers = _scene2modelAdptr.getPeers()
        let sortedScore: NSMutableArray = NSMutableArray(array: peers)
        let sortByScore = NSSortDescriptor(key: "score", ascending: false)
        let sortDescriptors = [sortByScore]
        sortedScore.sortUsingDescriptors(sortDescriptors)
        var peerScore = NSArray(array: sortedScore) as! [Peer]

        
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
                icnStar.position = CGPoint(x: lblScore.position.x + CGFloat(star) * (icnStar.size.width), y: lblScore.position.y - CGFloat(index + 1) * 100)
                addChild(icnStar)
            }
        }
        
        _scene2modelAdptr.clearGameData()
        
        btnNext = SKSpriteNode(imageNamed: "200x200_button_next")
        btnNext.position = CGPoint(x: size.width - 300, y: 400)
        addChild(btnNext)
        
        if (_scene2modelAdptr.getPlayerID() == 0) {
            btnAgain = SKSpriteNode(imageNamed: "200x200_button_replay")
            btnAgain.position = CGPoint(x: size.width - 500, y: 400)
            addChild(btnAgain)
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            let loc = touch.locationInNode(self)
            if btnNext != nil && btnNext.containsPoint(loc){
                _scene2modelAdptr.setGameMode(GameMode.None)
                UIView.transitionWithView(view!, duration: 0.5,
                    options: UIViewAnimationOptions.TransitionFlipFromBottom,
                    animations: {
                        self.view!.removeFromSuperview()
                        self._scene2controllerAdptr.clearCurrentView()
                    }, completion: nil)
                
            }
            if btnAgain != nil && btnAgain.containsPoint(loc){
                if _scene2modelAdptr.getNumActivePlayers() < _scene2modelAdptr.getMaxPlayer() {
                    var alert = UIAlertController(title: "Not Enough Players", message: "Please connect to \(_scene2modelAdptr.getMaxPlayer()) players to start the game)", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                    self._scene2controllerAdptr.presentViewController(alert, animated: true, completion: nil)
                } else {
                    _scene2controllerAdptr.transitToGame(_scene2modelAdptr.getGameMode(), gameState: _scene2modelAdptr.getGameState())
                }
            }
        }
    }
    
    override func className() -> String{
        return "LeaderBoardScene"
    }
    
}