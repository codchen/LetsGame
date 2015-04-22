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
    
    func deleteOpponentSlave(id: Int, message: MessageDead) {

        opponents[id]?.deleteIndex = Int(message.index)
        opponents[id]?.lastCount = message.count
    }
    
    func getOpponentByName(name: String) -> OpponentNodes? {
        for (id, opponent) in opponents {
            if opponent.sprite == name {
                return opponent
            }
        }
        return nil
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
    
    func updateReborn(id: Int, message: MessageReborn) {
        opponents[id]?.updateReborn(message)
    }
    
    func updateCaptured(id: Int, target: SKSpriteNode, capturedTime: NSTimeInterval, lastCount: UInt32) {
        for (player_id, opponent) in opponents {
            if id == player_id {
                opponent.capture(target, capturedTime: capturedTime)
                opponent.lastCount = lastCount
            } else {
                opponent.decapture(target)
            }
        }
    }
    
    func decapture(target: SKSpriteNode){
        for (id, opponent) in opponents{
            opponent.decapture(target)
        }
    }
}