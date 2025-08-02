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
    @State private var scoreAnimation: (CGPoint, Color)? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                
                // MARK: - Header
                VStack {
                    Text("\(viewModel.currentPlayer.name)'s turn")
                        .font(.title2)
                        .foregroundColor(viewModel.currentPlayer.color)
                        .transition(.opacity.combined(with: .scale))
                    
                    Text("Find a cell with \(viewModel.currentTarget)")
                        .font(.headline)
                }
                .id(viewModel.currentPlayer.id)
                
                // MARK: - Game board
                GeometryReader { geo in
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: viewModel.settings.boardSize), spacing: 8) {
                        ForEach(viewModel.cells) { cell in
                            CellView(cell: cell,
                                     isHighlighted: isCellHighlighted(cell),
                                     isTarget: cell.row == viewModel.currentTarget || cell.col == viewModel.currentTarget)
                                .onTapGesture {
                                    let cellFrame = frameForCell(cell, in: geo.size)
                                    handleCellTap(cell, at: cellFrame)
                                }
                        }
                    }
                    .padding()
                }
                
                // MARK: - End game button
                Button("End Game") {
                    showResults = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // MARK: - HUD with scores
            HUDView(players: viewModel.settings.players)
            
            // MARK: - "+1" Animation
            if let anim = scoreAnimation {
                Text("+1")
                    .font(.title)
                    .foregroundColor(anim.1)
                    .position(anim.0)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.0)) {
                            scoreAnimation = nil
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showResults) {
            ResultsView(players: viewModel.settings.players)
        }
        .animation(.easeInOut, value: viewModel.currentPlayer.id)
    }
    
    // MARK: - Helpers
    
    private func handleCellTap(_ cell: Cell, at position: CGPoint) {
        if highlightedCell?.id == cell.id {
            let wasCorrect = viewModel.isCorrectSelection(cell)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.selectCell(cell)
            }
            
            if wasCorrect {
                scoreAnimation = (position, viewModel.currentPlayer.color)
            }
            
            highlightedCell = nil
            
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
    
    private func frameForCell(_ cell: Cell, in size: CGSize) -> CGPoint {
        let rows = viewModel.settings.boardSize
        let cols = rows
        let cellWidth = (size.width - 16) / CGFloat(cols)
        let cellHeight = (size.height - 16) / CGFloat(rows)
        
        let x = CGFloat(cell.col) * (cellWidth + 8) + cellWidth / 2
        let y = CGFloat(cell.row) * (cellHeight + 8) + cellHeight / 2
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - HUD View (scores in corners)

struct HUDView: View {
    let players: [Player]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if players.count > 0 {
                    scoreLabel(players[0], at: CGPoint(x: 50, y: 50))
                }
                if players.count > 1 {
                    scoreLabel(players[1], at: CGPoint(x: geo.size.width - 50, y: 50))
                }
                if players.count > 2 {
                    scoreLabel(players[2], at: CGPoint(x: 50, y: geo.size.height - 50))
                }
                if players.count > 3 {
                    scoreLabel(players[3], at: CGPoint(x: geo.size.width - 50, y: geo.size.height - 50))
                }
            }
        }
    }
    
    private func scoreLabel(_ player: Player, at pos: CGPoint) -> some View {
        VStack {
            Text(player.name)
                .font(.caption)
                .foregroundColor(player.color)
            Text("\(player.score)")
                .font(.title)
                .foregroundColor(player.color)
        }
        .position(pos)
    }
}
