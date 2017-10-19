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
   var moveSpeed: Double
   var startPos: SCNVector3
   
   init(paddle: SCNNode, difficulty: Difficulty) {
      paddleNode = paddle
      switch difficulty {
      case .easy:
         moveSpeed = 0.0001
      case .medium:
         moveSpeed = 0.0005
      case .hard:
         moveSpeed = 0.001
      }
      startPos = paddle.position
   }
   
   func moveTo(x: Float, y: Float) {
      paddleNode.position = SCNVector3(x, y, paddleNode.position.z)
   }
   
   func returnToStart(){
      paddleNode.position = startPos
   }
   
}
