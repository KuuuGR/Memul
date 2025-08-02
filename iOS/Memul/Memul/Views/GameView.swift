//
//  GameView.swift
//  Memul
//
//  Created by admin on 02/08/2025.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var highlightedCell: Cell? = nil
    @State private var showResults = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Header - current player and target number
            VStack {
                Text("\(viewModel.currentPlayer.name)'s turn")
                    .font(.title2)
                    .foregroundColor(viewModel.currentPlayer.color)
                
                Text("Find a cell with \(viewModel.currentTarget)")
                    .font(.headline)
            }
            
            // Game board
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: viewModel.settings.boardSize), spacing: 8) {
                ForEach(viewModel.cells) { cell in
                    CellView(cell: cell,
                             isHighlighted: isCellHighlighted(cell),
                             isTarget: cell.row == viewModel.currentTarget || cell.col == viewModel.currentTarget)
                        .onTapGesture {
                            handleCellTap(cell)
                        }
                }
            }
            .padding()
            
            // End game button
            Button("End Game") {
                showResults = true
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .fullScreenCover(isPresented: $showResults) {
            ResultsView(players: viewModel.settings.players)
        }
    }
    
    // MARK: - Helpers
    
    private func handleCellTap(_ cell: Cell) {
        if highlightedCell?.id == cell.id {
            // Second tap - confirm selection
            viewModel.selectCell(cell)
            highlightedCell = nil
        } else {
            // First tap - highlight row and column
            highlightedCell = cell
        }
    }
    
    private func isCellHighlighted(_ cell: Cell) -> Bool {
        guard let highlighted = highlightedCell else { return false }
        return cell.row == highlighted.row || cell.col == highlighted.col
    }
}

// MARK: - Cell View

struct CellView: View {
    let cell: Cell
    let isHighlighted: Bool
    let isTarget: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(cell.isRevealed ? Color.gray.opacity(0.3) : Color.blue.opacity(isHighlighted ? 0.6 : 0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isTarget ? Color.red : Color.clear, lineWidth: 2)
                )
            
            if cell.isRevealed {
                Text("\(cell.value)")
                    .font(.headline)
                    .foregroundColor(.black)
            } else {
                Text("?")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 40)
    }
}

