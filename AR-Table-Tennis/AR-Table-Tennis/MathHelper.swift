//
//  MathHelper.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 25/9/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import Foundation

extension Double {
    static func degToRad(_ deg: Double) -> Double {
        return (deg * (Double.pi/Double(180)))
    }
    static func radToDeg(_ rad: Double) -> Double {
        return (rad * (Double(180)/Double.pi))
    }
}
