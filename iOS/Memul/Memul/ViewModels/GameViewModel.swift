//
//  GameViewModdels.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

//
//  GameViewModel.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var settings: GameSettings
    @Published var cells: [Cell] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var currentTarget: Int = 1
    @Published var isGameOver: Bool = false
    
    // MARK: - Computed Properties
    var players: [Player] {
        settings.players
    }
    
    var currentPlayer: Player {
        settings.players[currentPlayerIndex]
    }
    
    // MARK: - Init
    init(settings: GameSettings) {
        self.settings = settings
        generateBoard()
        pickNextTarget()
    }
    
    // MARK: - Board Generation
    /// Generates the multiplication board based on the selected size
    func generateBoard() {
        cells = []
        for row in 1...settings.boardSize {
            for col in 1...settings.boardSize {
                let value = row * col
                cells.append(Cell(row: row, col: col, value: value))
            }
        }
    }
    
    // MARK: - Game Logic
    
    /// Picks a new target number for which at least one unrevealed cell exists
    func pickNextTarget() {
        let unrevealedCells = cells.filter { !$0.isRevealed }
        let possibleNumbers = Set(unrevealedCells.flatMap { [$0.row, $0.col] })
        
        guard let random = possibleNumbers.randomElement() else {
            isGameOver = true
            return
        }
        currentTarget = random
    }
    
    /// Checks if the tapped cell is correct for the current target
    func isCorrectSelection(_ cell: Cell) -> Bool {
        return cell.row == currentTarget || cell.col == currentTarget
    }
    
    /// Handles the selection of a cell by the current player
    func selectCell(_ cell: Cell) {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        
        if isCorrectSelection(cell) {
            cells[index].isRevealed = true
            addPointToCurrentPlayer()
        }
        
        nextTurn()
    }
    
    /// Adds a point to the current player
    private func addPointToCurrentPlayer() {
        settings.players[currentPlayerIndex].score += 1
    }
    
    /// Proceeds to the next player's turn and picks a new target
    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % settings.players.count
        pickNextTarget()
        
        if cells.allSatisfy({ $0.isRevealed }) {
            isGameOver = true
        }
    }
}
