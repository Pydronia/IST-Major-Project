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
   static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
      return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
   }
   static func * (left: SCNVector3, right: Float) -> SCNVector3 {
      return SCNVector3(left.x * right, left.y * right, left.z * right)
   }
}

extension SCNMatrix4 {
   var worldPosition: SCNVector3 {
      return SCNVector3(self.m41, self.m42, self.m43)
   }
}

extension SCNNode {
   var forwardDirection: SCNVector3 {
      return SCNVector3(-self.transform.m31, -self.transform.m32, -self.transform.m33)
   }
   
   // Normalised vector direction between two points
   
}

