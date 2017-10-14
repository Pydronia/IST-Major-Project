//
//  MathHelper.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 25/9/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import Foundation
import SceneKit

extension Double {
    static func degToRad(_ deg: Double) -> Double {
        return (deg * (Double.pi/Double(180)))
    }
    static func radToDeg(_ rad: Double) -> Double {
        return (rad * (Double(180)/Double.pi))
    }
}

extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    static func * (left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3(left.x * right, left.y * right, left.z * right)
    }
   /*
   static func worldPositionFromTransform(_ transform: SCNMatrix4) -> SCNVector3 {
      return SCNVector3(transform.m41, transform.m42, transform.m43)
   }
    */
}

