//
//  SceneToModelAdapter.swift
//  OmniBall
//
//  Created by Fang on 4/8/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class SceneToModelAdapter: NSObject {
    
    var model: ConnectionManager!
    
    func setGameState(state: GameState) {
        model.gameState = state
    }
    
    func setGameMode(mode: GameMode) {
        model.gameMode = mode
    }
    
    func getGameMode() -> GameMode {
        return model.gameMode
    }
    
    func getGameState() -> GameState {
        return model.gameState
    }
    
    func getPlayerID() -> UInt16 {
        return model.me.playerID
    }
    
    func getPlayerName(#playerID: UInt16) -> String {
        return model.peersInGame.getPeerName(playerID)
    }
    
    func getScore(#playerID: UInt16) -> Int {
        return model.peersInGame.getScore(playerID)
    }
    
    func getDelta(playerID: Int) -> Double {
        return model.peersInGame.getDelta(playerID)
    }
    
    func getMaxPlayer() -> Int {
        return model.maxPlayer
    }
    
    func getMaxLevel() -> Int {
        return model.maxLevel
    }
    
    func getMaxScore() -> Int{
        return model.peersInGame.getMaxScore()
    }
    
    func getPeers() -> [Peer] {
        return model.peersInGame.peers
    }
    
    func increaseScore(#playerID: UInt16) {
        model.peersInGame.increaseScore(playerID)
    }
    
    func sendDestinationPos(x: Float, y: Float, rotate: Float, starX: Float, starY: Float) {
        model.sendDestinationPos(x, y: y, rotate: rotate, starX: starX, starY: starY)
    }
    
    func sendNeutralInfo(#index: UInt16, id: UInt16, lastCaptured: Double){
        model.sendNeutralInfo(index, id: id, lastCaptured: lastCaptured)
    }
    
    func sendReborn(#playerID: UInt16) {
        model.sendReborn(playerID)
    }
    
    func sendDeath(#index: UInt16, msgCount: UInt32) {
        model.sendDeath(index, count: msgCount)
    }
    
    func sendGameOver() {
        model.sendGameOver()
    }
    
    func sendPause(){
        model.sendPause()
    }
    
    func sendMove(x: Float, y: Float, dx: Float, dy: Float, count: UInt32, index: UInt16, dt: NSTimeInterval, isSlave: Bool){
        model.sendMove(x, y: y, dx: dx, dy: dy, count: count, index: index, dt: dt, isSlave: isSlave)
    }
    
    func clearGameData() {
        model.clearGameData()
    }
    
}
