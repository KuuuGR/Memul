//
//  GameView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI
import AVFoundation

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var highlightedCell: Cell? = nil
    @State private var showResults = false
    @State private var scoreAnimation: (CGPoint, Color)? = nil
    @State private var showConfetti = false
    
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
            
            // MARK: - HUD
            HUDView(players: viewModel.settings.players)
            
            // MARK: - "+1" animation
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
            
            // MARK: - Confetti animation
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showConfetti = false
                            }
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
                playCorrectSound()
                scoreAnimation = (position, viewModel.currentPlayer.color)
                withAnimation {
                    showConfetti = true
                }
            } else {
                playWrongSound()
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
    
    // MARK: - Sounds
    
    private func playCorrectSound() {
        AudioServicesPlaySystemSound(1057) // "success" sound
    }
    
    private func playWrongSound() {
        AudioServicesPlaySystemSound(1053) // "error" sound
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: 8, height: 8)
                        .position(particle.position)
                        .animation(.linear(duration: 1.0), value: particle.position)
                }
            }
            .onAppear {
                particles = (0..<20).map { _ in
                    ConfettiParticle(
                        id: UUID(),
                        position: CGPoint(x: CGFloat.random(in: 0..<geo.size.width), y: -10),
                        color: [Color.red, Color.green, Color.blue, Color.yellow, Color.purple].randomElement()!
                    )
                }
                
                for i in 0..<particles.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(i)) {
                        particles[i].position.y = geo.size.height + 20
                    }
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
}
