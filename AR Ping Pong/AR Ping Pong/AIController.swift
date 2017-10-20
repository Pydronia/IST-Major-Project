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
   
   init(paddle: SCNNode, difficulty: Difficulty) {
      paddleNode = paddle
      switch difficulty {
      case .easy:
         moveSpeed = 0.005
      case .medium:
         moveSpeed = 0.01
      case .hard:
         moveSpeed = 0.05
      }
      
      startPos = paddle.position
   }
   
   func moveTo(x: Float, y: Float) {
      // TODO: Test
      
      let destination = SCNVector3(x, y, 0)
      let vector = destination - paddleNode.position
      let vectorLength = sqrt(vector.x * vector.x + vector.y * vector.y)
      let normalisedVector = SCNVector3(vector.x/vectorLength, vector.y/vectorLength, 0)
      paddleNode.position = paddleNode.position + (normalisedVector * (vectorLength/10.0))
   }
   
   func returnToStart(){
      paddleNode.position = startPos
   }
   
}
