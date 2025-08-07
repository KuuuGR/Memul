//
//  GameSettings.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct IndexColors: Equatable {
    var top: Color = .blue
    var bottom: Color = .blue
    var left: Color = .red
    var right: Color = .red
    
    static let transparent = IndexColors(top: .clear, bottom: .clear, left: .clear, right: .clear)
    
}

struct IndexVisibility: Equatable {
    var top: Bool = true
    var bottom: Bool = true
    var left: Bool = true
    var right: Bool = true
}

struct GameSettings {
    var boardSize: Int = 4
    var players: [Player] = [
        Player(name: "Player 1", color: .red),
        Player(name: "Player 2", color: .blue)
    ]
    var useRandomPuzzleImage: Bool = false
    
    // Premium
    var isPremium: Bool = false
    
    // Index labels customization
    var indexColors: IndexColors = IndexColors()
    var indexVisibility: IndexVisibility = IndexVisibility()
    
    // Header coordinates button visibility
    var showSelectedCoordinatesButton: Bool = true
    
    static let freeMaxBoardSize = 6
    static let freeMaxPlayers = 4
    
}
