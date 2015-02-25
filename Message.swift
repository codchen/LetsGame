//
//  Message.swift
//  try
//
//  Created by Jiafang Jiang on 1/28/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation

enum MessageType: Int {
    case RandomNumber, GameStart, FirstTrip, SecondTrip, ThirdTrip, Move, Dead, Capture, GameOver
}

enum GameState: Int {
    case WaitingForMatch, WaitingForRandomNumber, WaitingForReconcil, WaitingForStart, InGame, Done
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

struct MessageGameStart {
    let message: Message
    let playerID: UInt16
}

struct MessageDead {
    let message: Message
    let index: UInt16
    let count: UInt32
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

struct MessageCapture {
    let message: Message
    let index: UInt16
    let time: NSTimeInterval
    let count: UInt32
}



