//
//  Cell.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import Foundation

struct Cell: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    let value: Int
    var isRevealed: Bool = false
}
