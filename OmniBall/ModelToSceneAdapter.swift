//
//  ModelToSceneAdapter.swift
//  OmniBall
//
//  Created by Fang on 4/8/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import UIKit

class ModelToSceneAdapter: NSObject {
    
    var scene: GameScene!
    
    func updateNeutralInfo(message: MessageNeutralInfo, peerPlayerID: Int){
        if scene != nil {
            scene.updateNeutralInfo(message, playerID: peerPlayerID)
        }
    }
    
    func updateReborn(message: MessageReborn, peerPlayerID: Int){
        if scene != nil {
            scene.updateReborn(message, peerPlayerID: peerPlayerID)
        }
    }
    
    func gameOver(){
        scene.gameOver(won: false)
    }
    
    func pause(){
        if scene != nil {
            scene.paused()
        }
    }
    
    func updatePeerPos(message: MessageMove, peerPlayerID: Int) {
        if scene != nil {
            scene.updatePeerPos(message, peerPlayerID: peerPlayerID)
        }
    }
    
    func updatePeerDeath(message: MessageDead, peerPlayerID: Int){
        if scene != nil {
            scene.deletePeerBalls(message, peerPlayerID: peerPlayerID)
        }
    }
    
    func playerExit(playerName: String) {
        if scene != nil {
            var alert = UIAlertController(title: "Player Exited Game", message: playerName + " has exit the game", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        	scene._scene2controllerAdptr.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
}
