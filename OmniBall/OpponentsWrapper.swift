//
//  OpponentsWrapper.swift
//  OmniBall
//
//  Created by Fang on 2/19/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

class OpponentsWrapper {
    
    var opponents: Dictionary<Int, OpponentNodes> = Dictionary<Int, OpponentNodes>()
    
    func addOpponent(opponent: OpponentNodes) {
        opponents[Int(opponent.id)] = opponent
    }
    
    func deleteOpponentBall(id: Int, message: MessageDead) {
        if Int(message.index) >= opponents[id]!.count{
            return
        }
        opponents[id]?.deleteIndex = Int(message.index)
        opponents[id]?.lastCount = message.count
    }
    
	func update_peer_dead_reckoning(){
        for (id, opponent) in opponents {
            opponent.update_peer_dead_reckoning()
        }

    }
    
	func checkDead(){
        for (id, opponent) in opponents {
            opponent.checkDead()
        }
    }
    
    func updatePeerPos(id: Int, message: MessageMove) {
        opponents[id]?.updatePeerPos(message)
    }
    
    func updateCaptured(id: Int, message: MessageCapture) {
        for (player_id, opponent) in opponents {
            if id == player_id {
                opponent.updateCaptured(message)
            } else {
                opponent.decapture(Int(message.index))
            }
        }
    }
    
    func decapture(index: Int){
        for (id, opponent) in opponents{
            opponent.decapture(index)
        }
    }
}