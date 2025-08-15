//
//  GameSettings.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

// MARK: - Difficulty

/// Difficulty levels for scoring rules.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy    // correct: +1, wrong: 0
    case normal  // correct: +1, wrong: -1 but not below 0
    case hard    // correct: +1, wrong: -1 (can go negative)

    var id: String { rawValue }
}

// MARK: - Index labels customization

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

// MARK: - Global settings container

/// Global game configuration passed into the view model and views.
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
    var enableIndexCustomization: Bool = false
    var indexColors: IndexColors = IndexColors()
    var indexVisibility: IndexVisibility = IndexVisibility()

    // UX
    var showSelectedCoordinatesButton: Bool = true

    // Quick Practice ranges & locks
    var isDivisionUnlocked: Bool = false          // premium-gated
    var multiplicationMin: Int = 1
    var multiplicationMax: Int = 10
    var divisionMin: Int = 1
    var divisionMax: Int = 10

    // Free version limits
    static let freeMaxBoardSize = 6
    static let freeMaxPlayers   = 4
}
