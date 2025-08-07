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
        VStack(spacing: 16) {

            // MARK: Header
            VStack(spacing: 8) {
                Text("\(viewModel.currentPlayer.name)'s turn")
                    .font(.title2)
                    .foregroundColor(viewModel.currentPlayer.color)
                    .transition(.opacity.combined(with: .scale))

                Text("Find a cell with \(viewModel.currentTarget)")
                    .font(.headline)

                if viewModel.settings.showSelectedCoordinatesButton {
                    coordinatesButton
                }
            }
            .id(viewModel.currentPlayer.id)
            .padding(.top, 20)

            // MARK: Scrollable Board (both directions)
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: spacing) {
                    // Top column numbers
                    HStack(spacing: spacing) {
                        Text("").frame(width: cellSize, height: cellSize)
                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            Text("\(col)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.top)
                                .opacity(viewModel.settings.indexVisibility.top ? 1 : 0)
                        }
                        Text("").frame(width: cellSize, height: cellSize)
                    }

                    // Rows with cells
                    ForEach(1...viewModel.settings.boardSize, id: \.self) { row in
                        HStack(spacing: spacing) {
                            // Left row number
                            Text("\(row)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.left)
                                .opacity(viewModel.settings.indexVisibility.left ? 1 : 0)

                            ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                                if let cell = viewModel.cells.first(where: { $0.row == row && $0.col == col }) {
                                    CellView(
                                        cell: cell,
                                        isHighlighted: isCellHighlighted(cell),
                                        isTarget: cell.value == viewModel.currentTarget,
                                        puzzlePiece: getPuzzlePiece(row: row, col: col),
                                        cellSize: cellSize
                                    )
                                    .frame(width: cellSize, height: cellSize)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        guard !cell.isRevealed else { return }
                                        handleTap(row: row, col: col, cell: cell)
                                    }
                                }
                            }

                            // Right row number
                            Text("\(row)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.right)
                                .opacity(viewModel.settings.indexVisibility.right ? 1 : 0)
                        }
                    }

                    // Bottom column numbers
                    HStack(spacing: spacing) {
                        Text("").frame(width: cellSize, height: cellSize)
                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            Text("\(col)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.bottom)
                                .opacity(viewModel.settings.indexVisibility.bottom ? 1 : 0)
                        }
                        Text("").frame(width: cellSize, height: cellSize)
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
                FlexibleScoreView(players: viewModel.settings.players, currentPlayerId: viewModel.currentPlayer.id)

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
            Group {
                if viewModel.showPuzzleOverlay, let image = viewModel.puzzleImageName {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { viewModel.dismissPuzzleOverlay() }

                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding()
                        .transition(.opacity)
                        .onTapGesture { viewModel.dismissPuzzleOverlay() }
                        .accessibilityLabel("Tap to close")
                }
            }
        )
        .fullScreenCover(isPresented: $showResults) {
            ResultsView(viewModel: viewModel)
        }
        .animation(.easeInOut, value: viewModel.currentPlayer.id)
    }

    // MARK: - Coordinates button
    private var coordinatesButton: some View {
        let coords = viewModel.currentSelection
        let rowText = coords?.row != nil ? "\(coords!.row)" : " "
        let colText = coords?.col != nil ? "\(coords!.col)" : " "

        return Button {
            // Submit only if we have a current selection
            viewModel.submitCurrentSelection()
        } label: {
            HStack(spacing: 8) {
                Text("(")
                    .foregroundColor(.secondary)
                Text(rowText)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.settings.indexColors.left)
                Text(",")
                    .foregroundColor(.secondary)
                Text(colText)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.settings.indexColors.top)
                Text(")")
                    .foregroundColor(.secondary)
            }
            .font(.title3) // bigger and more button-like
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("(\(rowText), \(colText))")
    }

    // MARK: - Tap handling
    private func handleTap(row: Int, col: Int, cell: Cell) {
        if let current = viewModel.currentSelection, current.row == row && current.col == col {
            // Second tap on same cell -> submit answer
            let wasCorrect = viewModel.isCorrectSelection(cell)
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.submitCurrentSelection()
            }
            if wasCorrect {
                playCorrectSound()
            } else {
                playWrongSound()
            }
        } else {
            // First tap -> set highlight/coordinates only
            viewModel.firstTap(row: row, col: col)
        }
    }

    // MARK: - Helpers
    private func isCellHighlighted(_ cell: Cell) -> Bool {
        if let sel = viewModel.currentSelection {
            return sel.row == cell.row || sel.col == cell.col
        }
        return false
    }

    private func playCorrectSound() { AudioServicesPlaySystemSound(1057) }
    private func playWrongSound() { AudioServicesPlaySystemSound(1053) }
    
    private func getPuzzlePiece(row: Int, col: Int) -> Image? {
        let r = row - 1
        let c = col - 1
        if viewModel.puzzlePieces.indices.contains(r),
           viewModel.puzzlePieces[r].indices.contains(c) {
            return viewModel.puzzlePieces[r][c]
        }
        return nil
    }
}
