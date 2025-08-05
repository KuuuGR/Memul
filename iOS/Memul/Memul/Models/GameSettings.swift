//
//  GameSettings.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct GameSettings {
    var boardSize: Int = 4
    var players: [Player] = [
        Player(name: "Player 1", color: .red),
        Player(name: "Player 2", color: .blue)
    ]
    var useRandomPuzzleImage: Bool = false

    static let freeMaxBoardSize = 6
    static let freeMaxPlayers = 4
}
