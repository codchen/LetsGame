//
//  ModelToSceneAdapter.swift
//  OmniBall
//
//  Created by Fang on 4/8/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation

class ModelToSceneAdapter: NSObject {
    
    var scene: GameScene!
    
    func updateNeutralInfo(message: MessageNeutralInfo, peerPlayerID: Int){
        scene.updateNeutralInfo(message, playerID: peerPlayerID)
    }
    
    func updateReborn(message: MessageReborn, peerPlayerID: Int){
       	scene.updateReborn(message, peerPlayerID: peerPlayerID)
    }
    
    func gameOver(){
        scene.gameOver(won: false)
    }
    
    func pause(){
        scene.paused()
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        if scene != nil {
            scene.updatePeerPos(message, peerPlayerID: peerPlayerID)
        }
    }
    
    func updatePeerDeath(message: MessageDead, peerPlayerID: Int){
        scene.deletePeerBalls(message, peerPlayerID: peerPlayerID)
    }
    
}
