//
//  Message.swift
//  try
//
//  Created by Jiafang Jiang on 1/28/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation

enum MessageType: Int {
    case GameInit, Move, GameOver, Drop, RawData
}

struct Message {
    let messageType: MessageType
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

struct MessageDrop {
    let message: Message
    let bornPosX: Float
    let bornPosY: Float
    
}

struct MessageRawData {
    let message: Message
    let dx: Float
    let dy: Float
}
