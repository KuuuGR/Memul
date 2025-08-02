//
//  GameViewModelTests.swift
//  Memul
//
//  Created by admin on 02/08/2025.
//

import XCTest
@testable import Memul

final class GameViewModelTests: XCTestCase {
    
    func makeViewModel(boardSize: Int = 3, playerCount: Int = 2) -> GameViewModel {
        let players = (1...playerCount).map {
            Player(name: "Player \($0)", color: .red)
        }
        let settings = GameSettings(boardSize: boardSize, players: players)
        return GameViewModel(settings: settings)
    }
    
    func testBoardGeneration() {
        let vm = makeViewModel(boardSize: 3)
        XCTAssertEqual(vm.cells.count, 9, "Board should contain boardSize * boardSize cells")
        XCTAssertEqual(vm.cells.first?.value, 1, "First cell should be 1 (1*1)")
    }
    
    func testPickNextTargetAlwaysValid() {
        let vm = makeViewModel(boardSize: 3)
        vm.pickNextTarget()
        XCTAssert((1...3).contains(vm.currentTarget), "Target should always be between 1 and board size")
    }
    
    func testScoreIncreasesWhenCorrectCellIsSelected() {
        var vm = makeViewModel(boardSize: 3)
        
        // Force target to 2
        vm.currentTarget = 2
        
        // Find a matching cell (row or col = 2)
        guard let matchingCell = vm.cells.first(where: { $0.row == 2 || $0.col == 2 }) else {
            XCTFail("There should be at least one matching cell")
            return
        }
        
        vm.selectCell(matchingCell)
        
        XCTAssertEqual(vm.settings.players[0].score, 1, "Score should increase after correct selection")
    }
    
    func testNoScoreWhenWrongCellSelected() {
        var vm = makeViewModel(boardSize: 3)
        
        // Force target to 1
        vm.currentTarget = 1
        
        // Pick a cell that does NOT match target
        guard let wrongCell = vm.cells.first(where: { $0.row != 1 && $0.col != 1 }) else {
            XCTFail("There should be at least one wrong cell")
            return
        }
        
        vm.selectCell(wrongCell)
        
        XCTAssertEqual(vm.settings.players[0].score, 0, "Score should not increase after wrong selection")
    }
    
    func testGameEndsWhenAllCellsRevealed() {
        var vm = makeViewModel(boardSize: 2) // 4 cells
        
        // Reveal all cells
        for i in 0..<vm.cells.count {
            vm.cells[i].isRevealed = true
        }
        
        vm.pickNextTarget()
        
        XCTAssertTrue(vm.isGameOver, "Game should end when all cells are revealed")
    }
}
