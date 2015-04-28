//
//  OmniBallUtil.swift
//  OmniBall
//
//  Created by Fang on 2/26/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

struct nodeInfo {
    var x: CGFloat
    var y: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var dt: CGFloat
    var index: UInt16
}

enum PlayerColors: Int{
    case Green = 0, Red, Blue, Yellow
}

enum ScrollDirection: Int{
    case up = 0, down, left, right
}

func closeEnough(point1: CGPoint, point2: CGPoint, distance: CGFloat) -> Bool{
    let offset = point1.distanceTo(point2)
    if offset >= distance{
        return false
    }
    return true
}

func isOutOfBound(node: SKSpriteNode, bound: CGFloat) -> Bool {
    if node.position.y > bound {
        return true
    } else {
        return false
    }
}

func getPlayerImageName(playerColor: PlayerColors, isSelected: Bool) -> String {
    if !isSelected {
        switch playerColor {
        case .Green:
            return "green_circle"
        case .Red:
            return "red_circle"
        case .Yellow:
            return "80x80_yellow_ball"
        case .Blue:
            return "blue_circle"
        }
    } else {
        switch playerColor {
        case .Green:
            return "green_ball"
        case .Red:
            return "red_ball"
        case .Yellow:
            return "80x80_yellow_ball_filled"
        case .Blue:
            return "blue_ball"
        }
    }
}

func getSlaveImageName(playerColor: PlayerColors, isSelected: Bool) -> String {
    
    if !isSelected {
        switch playerColor {
        case .Green:
            return "green_aster"
        case .Red:
            return "red_aster"
        case .Yellow:
            return "yellow_star"
        case .Blue:
            return "blue_aster"
        }
    } else {
        switch playerColor {
        case .Green:
            return "green_star"
        case .Red:
            return "red_star"
        case .Yellow:
            return "80x80_yellow_star_filled"
        case .Blue:
            return "blue_star"
        }
    }
}



