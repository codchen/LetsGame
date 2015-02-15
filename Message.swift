//
//  Message.swift
//  try
//
//  Created by Jiafang Jiang on 1/28/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation

enum MessageType: Int {
    case RandomNumber, GameStart, Move, GameOver, Dead
}

enum GameState: Int {
    case WaitingForMatch, WaitingForRandomNumber, WaitingForStart, InGame, Done
}

struct Message {
    let messageType: MessageType
}

struct MessageRandomNumber {
    let message: Message
    let number: UInt32
}

struct MessageGameStart {
    let message: Message
    let playerID: Int
}

struct MessageDead {
    let message: Message
    let index: Int
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
}

struct MessageGameOver {
    let message: Message
}

