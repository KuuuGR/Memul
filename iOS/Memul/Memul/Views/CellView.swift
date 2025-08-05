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
    let puzzlePiece: Image?   // New: pre-sliced puzzle piece for this cell
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isHighlighted ? Color.yellow : Color.gray, lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(cell.isRevealed ? Color.gray.opacity(0.3) : Color.blue))
                .frame(width: cellSize, height: cellSize)

            if cell.isRevealed, let piece = puzzlePiece {
                piece
                    .resizable()
                    .frame(width: cellSize, height: cellSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if cell.isRevealed {
                Text("\(cell.value)")
                    .foregroundColor(.black)
                    .font(.headline)
            } else if isTarget {
                Text("?")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}
