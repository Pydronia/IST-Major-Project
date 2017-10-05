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

public class GameState {
    
    var currentState: State
    
    init(initialState: State){
        currentState = initialState
    }
    
    
    
}
