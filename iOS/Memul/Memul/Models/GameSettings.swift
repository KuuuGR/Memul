//
//  GameSettings.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct GameSettings {
    var boardSize: Int
    var players: [Player]
    
    // wersja darmowa ma ograniczenie
    static let freeMaxBoardSize = 5
    static let freeMaxPlayers = 2
}
