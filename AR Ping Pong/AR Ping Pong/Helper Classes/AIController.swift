//
//  AIController.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 19/10/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import Foundation
import SceneKit

public enum Difficulty {
   case easy
   case medium
   case hard
}

public class AIController {
   
   var paddleNode: SCNNode
   var moveSpeed: Float
   var startPos: SCNVector3
   var lowerLimit: Float
   
   init(paddle: SCNNode, difficulty: Difficulty) {
      paddleNode = paddle
      // lower is faster
      switch difficulty {
      case .easy:
         moveSpeed = 10
         lowerLimit = 0.10
      case .medium:
         moveSpeed = 7
         lowerLimit = 0.8
      case .hard:
         moveSpeed = 5
         lowerLimit = 0.06
      }
      
      if UIScreen.main.maximumFramesPerSecond == 60 {
         moveSpeed /= 2
      }
      
      startPos = paddle.position
   }
   
   func moveTo(x: Float, y: Float) {
      // TODO: Test
      
      let destination = SCNVector3(x, y, 0)
      let vector = destination - paddleNode.position
      let vectorLength = sqrt(vector.x * vector.x + vector.y * vector.y)
      let normalisedVector = SCNVector3(vector.x/vectorLength, vector.y/vectorLength, 0)
      var speed = vectorLength/moveSpeed
      
      if vectorLength > 1.5 {
         speed = 2/moveSpeed
      } else if vectorLength < lowerLimit {
         speed = lowerLimit/moveSpeed
      }
      
      if vectorLength < lowerLimit/moveSpeed {
         speed = vectorLength/moveSpeed
      }
      
      paddleNode.position = paddleNode.position + (normalisedVector * speed)
   }
   
   func returnToStart(){
      paddleNode.position = startPos
   }
   
}
