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
    
    var slaveNode: SKSpriteNode!
    var playerNode: SKSpriteNode!
    var successNode: Int = 0
    var bornPos: CGPoint!
    var selectedNode: SKSpriteNode!
    var launchTime: NSDate!
    var launchPoint: CGPoint!
    var color = PlayerColors.Green
    let maxSpeed:CGFloat = 1500

    let tapLabel = SKLabelNode()
    var flashAction: SKAction!
//    var hadFirstSelect: Bool = false
    var hadFirstStarSelect: Bool = false
    var hadFirstCapture: Bool = false
    var controller: ViewController!
    
    override func didMoveToView(view: SKView) {

//        _scene2modelAdptr = SceneToModelAdapter()
//        _scene2modelAdptr.model = ConnectionManager()
//        myNodes = MyNodes(scene2modelAdptr: _scene2modelAdptr, scene: self)
//        println("np4")
//        enableBackgroundMove = false
//        maxSucessNodes = 1
        setupPlayer()
        setupDestination(true)
        setupNeutral()
//        setupHUD()
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
    
    func setupPlayer() {
        playerNode = childNodeWithName("node1") as SKSpriteNode
        playerNode.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: getPlayerImageName(color, true)), alphaThreshold: 0.99, size: CGSize(width: 150, height: 150))
            //node1.physicsBody = SKPhysicsBody(circleOfRadius: node1.size.width / 2 - 25)
        playerNode.physicsBody?.linearDamping = 0
        playerNode.physicsBody?.restitution = 1

        playerNode.physicsBody?.categoryBitMask = physicsCategory.Me
        playerNode.physicsBody?.contactTestBitMask = physicsCategory.target | physicsCategory.Opponent | physicsCategory.wall
        selectedNode = playerNode
        bornPos = playerNode.position
    }
    
    override func setupDestination(origin: Bool) {
        destPointer = childNodeWithName("destPointer") as SKSpriteNode
        destPointer.zPosition = -5
        destHeart = SKShapeNode(circleOfRadius: 180)
        destHeart.fillColor = UIColor.blackColor()
        destHeart.zPosition = -10
        destHeart.position = destPointer.position
        addChild(destHeart)
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
//        addChild(tapLabel)
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
            addChild(tapLabel)
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
        if successNode == 1 {
            gameOver = true
            gameOver(won: true)
        }
    }
    
    override func gameOver(#won: Bool) {
        tapLabel.removeAllActions()
        let tutorialOverScene = TutorialOverScene(size: self.size)
        tutorialOverScene.controller = controller
        tutorialOverScene.scaleMode = scaleMode
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(tutorialOverScene, transition: reveal)
    }
    
    override func didEvaluateActions() {
        
    }
    
    override func didSimulatePhysics() {
        
    }
    
    func capture(#target: SKSpriteNode) {
        if !hadFirstCapture {
            target.physicsBody?.dynamic = true
            target.texture = SKTexture(imageNamed: getSlaveImageName(color, false))
            if !selectedNode.name!.hasPrefix("neutral"){
                selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, false))
            }
            selectedNode = target
            captureAnimation(target, isOppo: false)
            runAction(catchStarSound)
            
            
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
    }
    
    func captureAnimation(target: SKSpriteNode, isOppo: Bool){
        let originalTexture = SKTexture(imageNamed: getSlaveImageName(color, false))
        let changedTexture = SKTexture(imageNamed: getSlaveImageName(color, true))
        let block1 = SKAction.runBlock {
            target.texture = originalTexture
        }
        let block2 = SKAction.runBlock {
            target.texture = changedTexture
        }
        let wait = SKAction.waitForDuration(0.23)
        var flashAction: SKAction!
        if isOppo {
            flashAction = SKAction.sequence([block2, wait, block1, wait])
        } else {
            flashAction = SKAction.sequence([block1, wait, block2, wait])
        }
        target.removeAllActions()
        target.runAction(SKAction.repeatAction(flashAction, count: 4))
    }
    
    override func setupNeutral() {
        
        slaveNode = childNodeWithName("neutral0") as SKSpriteNode
        slaveNode.size = CGSize(width: 110, height: 110)
        slaveNode.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "80x80_orange_star"), size: CGSize(width: 110, height: 110))
        slaveNode.physicsBody!.restitution = 1
        slaveNode.physicsBody!.linearDamping = 0
        slaveNode.physicsBody!.categoryBitMask = physicsCategory.target
        slaveNode.physicsBody!.contactTestBitMask = physicsCategory.Me
        
    }
    
    override func scored() {
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let loc = touch.locationInNode(self)
        if closeEnough(loc, playerNode.position, CGFloat(250)) == true{
            touchesBeganHelper(playerNode, location: loc, isSlave: false)
            launchPoint = loc
            launchTime = NSDate()
        }
        
        if hadFirstCapture {
            if closeEnough(loc, slaveNode.position, CGFloat(280)) == true {
                touchesBeganHelper(slaveNode, location: loc, isSlave: true)
                launchPoint = loc
                launchTime = NSDate()
            }
        }
        
        if !hadFirstStarSelect && selectedNode.name!.hasPrefix("neutral") {
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
    
    
    func touchesBeganHelper(node: SKSpriteNode, location: CGPoint, isSlave: Bool) {
        if selectedNode.name!.hasPrefix("neutral"){
            selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, false))
        } else {
            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, false))
        }
        selectedNode = node
        
        if isSlave {
            selectedNode.texture = SKTexture(imageNamed: getSlaveImageName(color, true))
        } else {
            selectedNode.texture = SKTexture(imageNamed: getPlayerImageName(color, true))
        }
        
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        
    }
    
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent){
        let touch = touches.anyObject() as UITouch
        let location = touch.locationInNode(self)
        if (launchTime != nil && launchPoint != nil) {
            let now = NSDate()
            var offset: CGPoint = (location - launchPoint)/CGFloat(now.timeIntervalSinceDate(launchTime!))
            if offset.length() > maxSpeed{
                offset.normalize()
                offset.x = offset.x * maxSpeed
                offset.y = offset.y * maxSpeed
            }
            selectedNode.physicsBody?.velocity = CGVector(dx: offset.x / 2.3, dy: offset.y / 2.3)
            launchTime = nil
            launchPoint = nil
        }
    }
    
    override func didBeginContact(contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        var slaveNode: SKSpriteNode = contact.bodyA.node! as SKSpriteNode
        var hunterNode: SKSpriteNode = contact.bodyB.node! as SKSpriteNode
        
        if collision == physicsCategory.Me | physicsCategory.target{
            if contact.bodyB.node!.name?.hasPrefix("neutral") == true{
                slaveNode = contact.bodyB.node! as SKSpriteNode
            }
            runAction(collisionSound)
            capture(target: slaveNode)
        }
    }
    
    func checkOutOfBound(){
        if slaveNode.intersectsNode(destHeart) {
            successNode += 1
        }
        
        if playerNode.intersectsNode(destHeart) {
            playerNode.position = bornPos
        }
        
    }

}