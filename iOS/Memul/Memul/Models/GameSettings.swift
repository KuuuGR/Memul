//
//  GameSettings.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

/// Difficulty levels for scoring rules.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy    // correct: +1, wrong: 0
    case normal  // correct: +1, wrong: -1 but not below 0
    case hard    // correct: +1, wrong: -1 (can go negative)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .normal: return "Normal"
        case .hard:   return "Hard"
        }
    }
}

/// Colors of index labels around the board.
struct IndexColors: Equatable {
    var top: Color = .blue
    var bottom: Color = .blue
    var left: Color = .red
    var right: Color = .red
    
    static let transparent = IndexColors(top: .clear, bottom: .clear, left: .clear, right: .clear)
}

/// Visibility of index labels around the board.
struct IndexVisibility: Equatable {
    var top: Bool = true
    var bottom: Bool = true
    var left: Bool = true
    var right: Bool = true
}

/// Global game configuration passed into the view model.
struct GameSettings {
    // Board
    var boardSize: Int = 4

    // Players
    var players: [Player] = [
        Player(name: "Player 1", color: .red),
        Player(name: "Player 2", color: .blue)
    ]

    // Puzzle image behavior
    var useRandomPuzzleImage: Bool = false

    // Scoring rules
    var difficulty: Difficulty = .easy

    // Premium access
    var isPremium: Bool = false

    // Per-turn time limit (nil = unlimited)
    var turnTimeLimit: Int? = 30

    // Index headers customization
    var indexColors: IndexColors = IndexColors()
    var indexVisibility: IndexVisibility = IndexVisibility()

    // UX
    var showSelectedCoordinatesButton: Bool = true

    // Free version limits
    static let freeMaxBoardSize = 6
    static let freeMaxPlayers   = 4
}
