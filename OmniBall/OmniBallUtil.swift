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