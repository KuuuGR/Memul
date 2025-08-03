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
        VStack(spacing: 20) {
            
            // MARK: Header (fixed top)
            VStack {
                Text("\(viewModel.currentPlayer.name)'s turn")
                    .font(.title2)
                    .foregroundColor(viewModel.currentPlayer.color)
                    .transition(.opacity.combined(with: .scale))
                
                Text("Find a cell with \(viewModel.currentTarget)")
                    .font(.headline)
            }
            .id(viewModel.currentPlayer.id)
            .padding(.top, 20)
            
            // MARK: Scrollable board area (both horizontal and vertical)
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 2) {
                    // Column headers
                    HStack(spacing: 2) {
                        Text("") // Empty corner
                            .frame(width: 40, height: 40)
                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            Text("\(col)")
                                .frame(width: 40, height: 40)
                                .font(.caption)
                        }
                    }
                    
                    // Rows with row header + cells
                    ForEach(1...viewModel.settings.boardSize, id: \.self) { row in
                        HStack(spacing: 2) {
                            Text("\(row)")
                                .frame(width: 40, height: 40)
                                .font(.caption)
                            
                            ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                                if let cell = viewModel.cells.first(where: { $0.row == row && $0.col == col }) {
                                    CellView(
                                        cell: cell,
                                        isHighlighted: isCellHighlighted(cell),
                                        isTarget: cell.value == viewModel.currentTarget
                                    )
                                    .frame(width: 40, height: 40)
                                    .onTapGesture {
                                        guard !cell.isRevealed else { return }
                                        // Using .zero here; if you want exact positions, you can calculate separately
                                        handleCellTap(cell, at: CGPoint.zero)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                // Force minimum size to allow scrolling when content is larger than screen
                .frame(
                    minWidth: CGFloat(viewModel.settings.boardSize + 1) * 40 + 16,
                    minHeight: CGFloat(viewModel.settings.boardSize + 1) * 40 + 16
                )
            }
            
            // MARK: Scores and End Game Button (fixed bottom)
            VStack(spacing: 10) {
                HUDView(
                    players: viewModel.settings.players,
                    currentPlayerIndex: viewModel.settings.players.firstIndex(where: { $0.id == viewModel.currentPlayer.id })
                )
                
                Button("End Game") {
                    showResults = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.bottom, 20)
            .background(Color(UIColor.systemBackground))
        }
        .overlay(
            ZStack {
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
                
                if showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation { showConfetti = false }
                            }
                        }
                }
            }
        )
        .fullScreenCover(isPresented: $showResults) {
            ResultsView(viewModel: viewModel)
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
                withAnimation { showConfetti = true }
            } else {
                playWrongSound()
            }
            
            highlightedCell = nil
        } else {
            highlightedCell = cell
        }
    }
    
    private func isCellHighlighted(_ cell: Cell) -> Bool {
        guard let highlighted = highlightedCell else { return false }
        return cell.row == highlighted.row || cell.col == highlighted.col
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
