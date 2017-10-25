//
//  GameState.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 4/10/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import Foundation
import UIKit

public enum State {
   case planeMapping
   case setup
   case ready
   case playing
   case endGame
}

public enum Player {
   case user
   case computer
}

public class GameState {
   
   var currentState: State
   
   var playerScore: Int = 0
   var aiScore: Int = 0
   
   var lastPaddle: Player = .user
   
   var paddleCount: Int = 0
   var tableOneSideBounce: Int = 0
   var currentSide: Player = .user
   
   var aiController: AIController!
   var viewController: ViewController
   var scoreLabel: UILabel
   
   init(initialState: State, vc: ViewController, sl: UILabel){
      currentState = initialState
      viewController = vc
      scoreLabel = sl
   }
   
   func scoreFor(_ player: Player) {
      self.currentState = .ready
      switch player {
      case .user:
         playerScore += 1
      case .computer:
         aiScore += 1
      }
      DispatchQueue.main.async {
         self.scoreLabel.text = "\(self.playerScore)  :  \(self.aiScore)"
         self.scoreLabel.isHidden = false
      }
      
      if playerScore >= 10 {
         viewController.youWin()
      } else if aiScore >= 10 {
         viewController.youLose()
      }
      
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
         self.viewController.resetBall()
      }
      
      
   }
   
   
   
}
