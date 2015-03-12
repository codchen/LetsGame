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
    
    let tapLabel = SKLabelNode(text: "Tap to select the ball")
    var firstSelect: Bool = false
    
    override func didMoveToView(view: SKView) {
        connection = ConnectionManager()
        connection.assistant.stop()
        myNodes = MyNodes(connection: connection, scene: self)
        setupDestination()
        setupNeutral()
        setupHUD()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
        tapToSelect()
        
    }
    
    func tapToSelect(){
        let wait = SKAction.waitForDuration(0.5)
        
        tapLabel.fontColor = UIColor.whiteColor()
        tapLabel.fontName = "Chalkduster"
        tapLabel.fontSize = 60
        tapLabel.position = CGPoint(x: 878, y: 618)
        tapLabel.horizontalAlignmentMode = .Center
        tapLabel.name = "tap"
        let flashAction = SKAction.sequence([SKAction.scaleTo(1.2, duration: 0.6), SKAction.scaleTo(1.0, duration: 0.6)])
        
        let block = SKAction.runBlock {
        	self.addChild(self.tapLabel)
            self.tapLabel.runAction(SKAction.repeatActionForever(flashAction))
        }

        self.runAction(SKAction.sequence([wait, block]))
    }
    
    override func update(currentTime: CFTimeInterval) {
        
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
                    println("Hunter \(hunter.sprite) captured \(target.name!)")
                    assert(hunter.slaves[target.name!] == nil, "hunter is not nil before capture")
                    hunter.capture(target, capturedTime: now)
                    assert(hunter.slaves[target.name!] != nil, "Hunter didn't captured \(target.name!)")
                    
                    hudMinions[index].texture = target.texture
                    neutralBalls[target.name!]?.lastCapture = now
                    connection.sendNeutralInfo(UInt16(index), id: hunter.id, lastCaptured: now)
        }
    }

}