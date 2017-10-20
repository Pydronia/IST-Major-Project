//
//  GameState.swift
//  AR-Table-Tennis
//
//  Created by Jack Carey on 4/10/17.
//  Copyright © 2017 Jack Carey. All rights reserved.
//

import Foundation

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
   
   var playerToServe: Player = .user
   
   init(initialState: State){
      currentState = initialState
   }
   
   func scoreFor(_ player: Player) {
      switch player {
      case .user:
         playerScore += 1
      case .computer:
         aiScore += 1
      }
   }
   
   
   
}
