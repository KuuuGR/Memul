//
//  CellView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct CellView: View {
    let cell: Cell
    let isHighlighted: Bool
    let isTarget: Bool
    let puzzlePiece: Image?   // Pre-sliced puzzle piece
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isHighlighted ? Color.yellow : Color.gray, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cell.isRevealed ? Color.clear : Color.blue)
                )
                .frame(width: cellSize, height: cellSize)

            // Puzzle piece if revealed
            if cell.isRevealed, let piece = puzzlePiece {
                piece
                    .resizable()
                    .frame(width: cellSize, height: cellSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Content overlay
            if cell.isRevealed {
                Text("\(cell.value)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 1.5, x: 0, y: 0)
            } else if isTarget {
                Text("") //TODO: GQtodo
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}
