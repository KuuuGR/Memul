//
//  PuzzlePieceView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 05/08/2025.
//

import SwiftUI

struct PuzzlePieceView: View {
    let imageName: String
    let row: Int
    let col: Int
    let boardSize: Int
    let cellSize: CGFloat

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: cellSize * CGFloat(boardSize),
                height: cellSize * CGFloat(boardSize)
            )
            .clipped()
            .offset(
                x: -CGFloat(col - 1) * cellSize,
                y: -CGFloat(row - 1) * cellSize
            )
    }
}
