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
    @Published var puzzlePieces: [[Image]] = []

    private let totalPuzzles = 7 // TODO: GQ_puzzle
    private let slicer: PuzzleSlicing
    private let random: RandomSourcing

    var players: [Player] { settings.players }
    var currentPlayer: Player { settings.players[currentPlayerIndex] }

    init(
        settings: GameSettings,
        slicer: PuzzleSlicing = PuzzleSlicer(),
        random: RandomSourcing = SystemRandomSource()
    ) {
        self.settings = settings
        self.slicer = slicer
        self.random = random
        selectPuzzleImage()
        generateBoard()
        pickNextTarget()
    }

    private func selectPuzzleImage() {
        if settings.useRandomPuzzleImage {
            let selectedIndex = random.int(in: 1...totalPuzzles)
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
                    puzzlePieceRect: nil
                ))
            }
        }
    }

    private func preparePuzzlePieces() {
        guard let puzzleName = puzzleImageName else {
            puzzlePieces = []
            return
        }
        puzzlePieces = slicer.slice(imageNamed: puzzleName, grid: settings.boardSize)
    }

    func pickNextTarget() {
        let unrevealed = cells.filter { !$0.isRevealed }
        let possibleNumbers = Array(Set(unrevealed.map { $0.value }))
        guard let next = random.element(from: possibleNumbers) else {
            isGameOver = true
            return
        }
        currentTarget = next
    }

    func isCorrectSelection(_ cell: Cell) -> Bool {
        cell.value == currentTarget
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
