//
//  GameViewModel.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    @Published var settings: GameSettings
    @Published var cells: [Cell] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var currentTarget: Int = 1
    @Published var isGameOver: Bool = false
    @Published var puzzleImageName: String? = nil
    @Published var puzzlePieces: [[Image]] = []  // Added to hold sliced pieces

    private let totalPuzzles = 2

    var players: [Player] {
        settings.players
    }
    
    var currentPlayer: Player {
        settings.players[currentPlayerIndex]
    }

    init(settings: GameSettings) {
        self.settings = settings
        selectPuzzleImage()
        generateBoard()
        pickNextTarget()
    }

    private func selectPuzzleImage() {
        if settings.useRandomPuzzleImage {
            let selectedIndex = Int.random(in: 1...totalPuzzles)
            puzzleImageName = "puzzle_\(selectedIndex)"
            preparePuzzlePieces()
        } else {
            puzzleImageName = nil
            puzzlePieces = []
        }
    }

    func generateBoard() {
        cells = []
        let size = settings.boardSize

        for row in 1...size {
            for col in 1...size {
                let value = row * col

                cells.append(Cell(
                    row: row,
                    col: col,
                    value: value,
                    puzzlePieceRect: nil  // No longer used
                ))
            }
        }
    }

    // New: Pre-slice the puzzle image into pieces
    private func preparePuzzlePieces() {
        guard let puzzleName = puzzleImageName,
              let uiImage = UIImage(named: puzzleName) else {
            puzzlePieces = []
            return
        }

        let size = settings.boardSize
        let imageSize = uiImage.size
        let pieceWidth = imageSize.width / CGFloat(size)
        let pieceHeight = imageSize.height / CGFloat(size)

        var pieces: [[Image]] = []

        for row in 0..<size {
            var rowPieces: [Image] = []
            for col in 0..<size {
                let cropRect = CGRect(
                    x: CGFloat(col) * pieceWidth,
                    y: CGFloat(row) * pieceHeight,
                    width: pieceWidth,
                    height: pieceHeight
                ).integral

                if let cgImage = uiImage.cgImage?.cropping(to: cropRect) {
                    let pieceUIImage = UIImage(cgImage: cgImage)
                    rowPieces.append(Image(uiImage: pieceUIImage))
                } else {
                    // If cropping fails, fallback to blank
                    rowPieces.append(Image(systemName: "questionmark.square"))
                }
            }
            pieces.append(rowPieces)
        }

        puzzlePieces = pieces
    }

    func pickNextTarget() {
        let unrevealedCells = cells.filter { !$0.isRevealed }
        let possibleNumbers = Set(unrevealedCells.map { $0.value })

        guard let random = possibleNumbers.randomElement() else {
            isGameOver = true
            return
        }
        currentTarget = random
    }

    func isCorrectSelection(_ cell: Cell) -> Bool {
        return cell.value == currentTarget
    }

    func selectCell(_ cell: Cell) {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }),
              !cells[index].isRevealed else {
            nextTurn()
            return
        }

        if cell.value == currentTarget {
            cells[index].isRevealed = true
            addPointToCurrentPlayer()
        }

        nextTurn()
    }

    private func addPointToCurrentPlayer() {
        settings.players[currentPlayerIndex].score += 1
    }

    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % settings.players.count
        pickNextTarget()
        
        if cells.allSatisfy({ $0.isRevealed }) {
            isGameOver = true
        }
    }
}
