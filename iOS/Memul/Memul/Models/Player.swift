//
//  Player.swift
//  Memul
//
//  Created by admin on 02/08/2025.
//

import SwiftUI

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var score: Int = 0
    var color: Color
}
