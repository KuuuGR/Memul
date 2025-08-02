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
    @State private var animateTurnChange = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Header with animation on player change
            VStack {
                Text("\(viewModel.currentPlayer.name)'s turn")
                    .font(.title2)
                    .foregroundColor(viewModel.currentPlayer.color)
                    .transition(.opacity.combined(with: .scale))
                
                Text("Find a cell with \(viewModel.currentTarget)")
                    .font(.headline)
            }
            .id(viewModel.currentPlayer.id) // Ensures animation on player change
            
            // MARK: - Game board
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
            
            // MARK: - End game button
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
        .animation(.easeInOut, value: viewModel.currentPlayer.id)
    }
    
    // MARK: - Helpers
    
    private func handleCellTap(_ cell: Cell) {
        if highlightedCell?.id == cell.id {
            // Confirm selection
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.selectCell(cell)
            }
            
            highlightedCell = nil
            
            // Delay before next turn to show result
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    viewModel.nextTurn()
                }
            }
        } else {
            highlightedCell = cell
        }
    }
    
    private func isCellHighlighted(_ cell: Cell) -> Bool {
        guard let highlighted = highlightedCell else { return false }
        return cell.row == highlighted.row || cell.col == highlighted.col
    }
}

// MARK: - Cell View with reveal animation

struct CellView: View {
    let cell: Cell
    let isHighlighted: Bool
    let isTarget: Bool
    @State private var revealScale: CGFloat = 0.0
    
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
                    .scaleEffect(revealScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            revealScale = 1.0
                        }
                    }
            } else {
                Text("?")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 40)
    }
}
