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
    
    override func didMoveToView(view: SKView) {
        connection = ConnectionManager()
        connection.assistant.stop()
        myNodes = MyNodes(connection: connection, scene: self)
        setupDestination()
        setupNeutral()
        setupHUD()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
//        destination = SKShapeNode(circleOfRadius: 422)
//        destination.position = childNodeWithName("destPointer")!.position
//        destination.fillColor = UIColor.lightGrayColor()
//        destination.zPosition = -10
//        addChild(destination)
        let maxAspectRatio: CGFloat = 16.0/9.0
        let maxAspectRatioHeight: CGFloat = size.width / maxAspectRatio
        let playableMargin: CGFloat = (size.height - maxAspectRatioHeight) / 2
        margin = playableMargin
        let playableRect: CGRect = CGRect(x: 0, y: playableMargin, width: size.width, height: size.height - playableMargin * 2)
    }

}