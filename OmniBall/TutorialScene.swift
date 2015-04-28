//
//  TutorialScene.swift
//  OmniBall
//
//  Created by Fang on 3/11/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class TutorialScene: GameScene {

    let tapLabel = SKLabelNode()
    var flashAction: SKAction!
//    var hadFirstSelect: Bool = false
    var hadFirstStarSelect: Bool = false
    var hadFirstCapture: Bool = false
    var vcontroller: ViewController!
    
    override func didMoveToView(view: SKView) {
        connection = ConnectionManager(pNum: 1)
        connection.advertiser.stopAdvertisingPeer()
        connection.browser.stopBrowsingForPeers()
        myNodes = MyNodes(connection: connection, scene: self)
        enableBackgroundMove = false
        maxSucessNodes = 1
        setupDestination(true)
        setupNeutral()
        setupHUD()
        setUpAction()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        swipeToHitStar()
        
    }
    
    override func setupDestination(origin: Bool) {
        destPointer = childNodeWithName("destPointer") as SKSpriteNode
        destPointer.zPosition = -5
        destHeart = SKShapeNode(circleOfRadius: 180)
        destHeart.fillColor = UIColor.blackColor()
        destHeart.zPosition = -10
        destHeart.position = destPointer.position
        AddChild(destHeart)
    }
    
    func setUpAction(){
        flashAction = SKAction.sequence([SKAction.scaleTo(1.2, duration: 0.5), SKAction.scaleTo(1.0, duration: 0.6)])
    }
    
//    func tapToSelect(){
//        tapLabel.fontColor = UIColor.whiteColor()
//        tapLabel.fontName = "Chalkduster"
//        tapLabel.fontSize = 60
//        tapLabel.horizontalAlignmentMode = .Center
//        tapLabel.name = "tap"
//        tapLabel.position = CGPoint(x: 878, y: 618)
//    
//        let text = "Tap to select the ball"
//        tapLabel.text = text
//        tapLabel.setScale(0)
//        AddChild(tapLabel)
//        let wait = SKAction.waitForDuration(0.2)
//        let block = SKAction.runBlock {
//            self.tapLabel.setScale(1)
//        }
//		tapLabel.runAction(SKAction.sequence([wait, block, SKAction.repeatActionForever(self.flashAction)]))
//    }
    
    func swipeToHitStar(){
            tapLabel.fontColor = UIColor.whiteColor()
            tapLabel.fontName = "Chalkduster"
            tapLabel.fontSize = 60
            tapLabel.horizontalAlignmentMode = .Center
            tapLabel.name = "tap"
            tapLabel.position = CGPoint(x: 900, y: 400)
        
            let text = "Swipe Your Ball to Hit the Star"
            tapLabel.text = text
            tapLabel.setScale(0)
            AddChild(tapLabel)
            let wait = SKAction.waitForDuration(0.2)
            let block = SKAction.runBlock {
                self.tapLabel.setScale(1)
            }
            tapLabel.runAction(SKAction.sequence([wait, block, SKAction.repeatActionForever(self.flashAction)]))
    }
    
    override func update(currentTime: CFTimeInterval) {
        if !gameOver {
            checkGameOver()
        }
        checkOutOfBound()
    }
    
    override func checkGameOver() {
        if myNodes.successNodes == 1 {
            gameOver = true
            connection.sendGameOver()
            gameOver(won: true)
        }
    }
    
    override func gameOver(#won: Bool) {
        tapLabel.removeAllActions()
        let tutorialOverScene = TutorialOverScene(size: self.size)
        tutorialOverScene.controller = vcontroller
        tutorialOverScene.scaleMode = scaleMode
//        tutorialOverScene.controller = self.controller
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(tutorialOverScene, transition: reveal)
    }
    
    override func didEvaluateActions() {
        
    }
    
    override func didSimulatePhysics() {
        
    }
    
    override func capture(#target: SKSpriteNode, hunter: Player) {
        let now = NSDate().timeIntervalSince1970
        let name: NSString = target.name! as NSString
        let index: Int = name.substringFromIndex(7).toInt()!
        let targetInfo = neutralBalls[target.name!]!
        
        if (now >= targetInfo.lastCapture + protectionInterval ||
            (now > targetInfo.lastCapture - protectionInterval &&
                now < targetInfo.lastCapture))&&(hunter.slaves[target.name!] == nil){
                    myNodes.decapture(target)
                    //println("Hunter \(hunter.sprite) captured \(target.name!)")
                    assert(hunter.slaves[target.name!] == nil, "hunter is not nil before capture")
                    hunter.capture(target, capturedTime: now)
                    assert(hunter.slaves[target.name!] != nil, "Hunter didn't captured \(target.name!)")
                    if !hadFirstCapture {
                        let text = "Swipe on the star"
                        tapLabel.removeAllActions()
                        tapLabel.setScale(0)
                        tapLabel.text = text
                        tapLabel.position = target.position - CGPoint(x: -200, y: 200)
                        let wait = SKAction.waitForDuration(0.2)
                        let block = SKAction.runBlock {
                            self.tapLabel.setScale(1)
                        }
                        tapLabel.runAction(SKAction.sequence([wait, block, SKAction.repeatActionForever(self.flashAction)]))
                        hadFirstCapture = true
                    }
//                    hudMinions[index].texture = target.texture
                    neutralBalls[target.name!]?.lastCapture = now
                    connection.sendNeutralInfo(UInt16(index), id: hunter.id, lastCaptured: now)
        }
    }
    
    override func setupNeutral() {
        
        var node = childNodeWithName("neutral0") as SKSpriteNode
        node.size = CGSize(width: 110, height: 110)
        node.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "80x80_orange_star"), size: CGSize(width: 110, height: 110))
        node.physicsBody!.restitution = 1
        node.physicsBody!.linearDamping = 0
        node.physicsBody!.categoryBitMask = physicsCategory.target
        node.physicsBody!.contactTestBitMask = physicsCategory.Me
        neutralBalls[node.name!] = NeutralBall(node: node, lastCapture: 0)
        
    }
    
    override func scored() {
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        myNodes.touchesBegan(loc)
		if !hadFirstStarSelect && myNodes.selectedNode.name!.hasPrefix("neutral") {
            let text = "Bring it into the ring"
            tapLabel.removeAllActions()
            tapLabel.setScale(0)
            tapLabel.text = text
            tapLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 300)
            let wait = SKAction.waitForDuration(0.2)
            let block = SKAction.runBlock {
                self.tapLabel.setScale(1)
            }
            tapLabel.runAction(SKAction.sequence([wait, block, SKAction.repeatActionForever(self.flashAction)]))
            hadFirstStarSelect = true
        }
    }

}