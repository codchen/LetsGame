//
//  OmniBallUtil.swift
//  OmniBall
//
//  Created by Fang on 2/26/15.
//  Copyright (c) 2015 Xiaoyu Chen. All rights reserved.
//

import Foundation
import SpriteKit

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
            return "80x80_green_ball"
        case .Red:
            return "80x80_red_ball"
        case .Yellow:
            return "80x80_yellow_ball"
        case .Blue:
            return "80x80_blue_ball"
        }
    } else {
        switch playerColor {
        case .Green:
            return "80x80_green_ball_filled"
        case .Red:
            return "80x80_red_ball_filled"
        case .Yellow:
            return "80x80_yellow_ball_filled"
        case .Blue:
            return "80x80_blue_ball_filled"
        }
    }
}

func getSlaveImageName(playerColor: PlayerColors, isSelected: Bool) -> String {
    if !isSelected {
        switch playerColor {
        case .Green:
            return "80x80_green_star"
        case .Red:
            return "80x80_red_star"
        case .Yellow:
            return "yellow_star"
        case .Blue:
            return "blue_star"
        }
    } else {
        switch playerColor {
        case .Green:
            return "80x80_green_star_filled"
        case .Red:
            return "80x80_red_star_filled"
        case .Yellow:
            return "80x80_yellow_star_filled"
        case .Blue:
            return "80x80_blue_star_filled"
        }
    }
}
