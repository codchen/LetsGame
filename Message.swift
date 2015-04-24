//
//  Message.swift
//  try
//
//  Created by Jiafang Jiang on 1/28/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation

enum MessageType: Int {
    case RandomNumber, GameReady, GameStart, FirstTrip, SecondTrip, ThirdTrip, Destination, Move, Pause, Dead, GameOver, NeutralInfo, Reborn, Exit
}

enum GameState: Int {
    case WaitingForMatch, WaitingForRandomNumber, WaitingForReconcil, WaitingForStart, InGame, Done, InViewController, InGameViewController
}

enum GameMode: Int {
    case None, BattleArena, HiveMaze, PoolArena, HiveMaze2
}

struct Message {
    let messageType: MessageType
}

struct MessageFirstTrip {
    let message: Message
    let time: NSTimeInterval
}

struct MessageSecondTrip {
    let message: Message
    let time: NSTimeInterval
    let delta: NSTimeInterval
}

struct MessageThirdTrip {
    let message: Message
    let delta: NSTimeInterval
}

struct MessageRandomNumber {
    let message: Message
    let number: UInt32
}

struct MessageReadyToGame {
    let message: Message
    let playerID: UInt16
}

struct MessageGameStart {
    let message: Message
    let gameMode: UInt16
}

struct MessageDead {
    let message: Message
    let index: UInt16
    let count: UInt32
}

struct MessageReborn {
    let message: Message
    let index: UInt16
}

struct MessageMove {
    let message: Message
    let x: Float
    let y: Float
    let dx: Float
    let dy: Float
    let count: UInt32
    let index: UInt16
    let dt: NSTimeInterval
    let isSlave: Bool
}

struct MessageGameOver {
    let message: Message
}

struct MessageNeutralInfo{
    let message: Message
    let index: UInt16
    let id: UInt16
    let lastCaptured: Double
}

struct MessageDestination {
    let message: Message
    let x: Float
    let y: Float
    let rotate: Float
    let starX: Float
    let starY: Float
}

struct MessagePause {
    let message: Message
}

struct MessageExit {
    let message: Message
}



