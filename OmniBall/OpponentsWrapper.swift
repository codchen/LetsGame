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
        opponents[opponent.id] = opponent
    }
    
    func deleteOpponentBall(id: Int, ballIndex: Int) {
        opponents[id]?.deleteIndex = ballIndex
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
}