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

    private let cellSize: CGFloat = 40
    private let spacing: CGFloat = 2

    var body: some View {
        VStack(spacing: 20) {

            // MARK: Header
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

            // MARK: Scrollable Board (both directions)
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: spacing) {
                    // ✅ Top column numbers
                    HStack(spacing: spacing) {
                        Text("")
                            .frame(width: cellSize, height: cellSize)
                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            Text("\(col)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                        }
                        Text("") // for right corner
                            .frame(width: cellSize, height: cellSize)
                    }

                    // ✅ Rows with cells
                    ForEach(1...viewModel.settings.boardSize, id: \.self) { row in
                        HStack(spacing: spacing) {
                            // Left row number
                            Text("\(row)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)

                            ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                                if let cell = viewModel.cells.first(where: { $0.row == row && $0.col == col }) {
                                    CellView(
                                        cell: cell,
                                        isHighlighted: isCellHighlighted(cell),
                                        isTarget: cell.value == viewModel.currentTarget
                                    )
                                    .frame(width: cellSize, height: cellSize)
                                    .onTapGesture {
                                        guard !cell.isRevealed else { return }
                                        handleCellTap(cell, at: .zero)
                                    }
                                }
                            }

                            // ✅ Right row number
                            Text("\(row)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                        }
                    }

                    // ✅ Bottom column numbers
                    HStack(spacing: spacing) {
                        Text("")
                            .frame(width: cellSize, height: cellSize)
                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            Text("\(col)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                        }
                        Text("") // for bottom-right corner
                            .frame(width: cellSize, height: cellSize)
                    }
                }
                .padding()
                .frame(
                    minWidth: CGFloat(viewModel.settings.boardSize + 2) * cellSize + spacing,
                    minHeight: CGFloat(viewModel.settings.boardSize + 2) * cellSize + spacing
                )
            }

            // MARK: HUD + Button
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
        highlightedCell.map { $0.row == cell.row || $0.col == cell.col } ?? false
    }

    private func playCorrectSound() { AudioServicesPlaySystemSound(1057) }
    private func playWrongSound() { AudioServicesPlaySystemSound(1053) }
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
