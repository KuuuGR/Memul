import XCTest
import SwiftUI
@testable import Memul

@MainActor
final class GameViewModelTests: XCTestCase {

    private func makePlayers(_ n: Int) -> [Player] {
        (1...n).map { Player(name: "P\($0)", color: .red) }
    }

    private func makeVM(
        boardSize: Int = 3,
        players: [Player]? = nil,
        random: RandomSourcing? = nil,
        slicer: PuzzleSlicing? = nil
    ) -> GameViewModel {
        let settings = GameSettings(
            boardSize: boardSize,
            players: players ?? makePlayers(2),
            useRandomPuzzleImage: false
        )
        return GameViewModel(
            settings: settings,
            slicer: slicer ?? MockPuzzleSlicer(),
            random: random ?? SystemRandomSource()
        )
    }

    func testBoardGeneration_countAndFirstValue() {
        let vm = makeVM(boardSize: 3)
        XCTAssertEqual(vm.cells.count, 9)
        XCTAssertEqual(vm.cells.first?.value, 1) // 1*1
    }

    func testPickNextTarget_usesRandomSourceOnUnrevealedValues() {
        let random = MockRandomSource()
        random.elements = [6] // force target
        let vm = makeVM(boardSize: 3, random: random)

        vm.pickNextTarget()
        XCTAssertEqual(vm.currentTarget, 6)
    }

    func testScoreIncreasesOnCorrectSelection() {
        let vm = makeVM(boardSize: 3, players: makePlayers(1))
        // Pick a value to target (e.g., 4 exists for 3x3)
        let cell = vm.cells.first(where: { $0.value == 4 }) ?? vm.cells[0]
        vm.currentTarget = cell.value

        vm.selectCell(cell)
        XCTAssertEqual(vm.settings.players[0].score, 1)
        XCTAssertTrue(vm.cells.first(where: { $0.id == cell.id })?.isRevealed ?? false)
    }

    func testNoScoreOnWrongSelection() {
        let vm = makeVM(boardSize: 3)
        // Pick a cell that won't match the target
        let wrongCell = vm.cells.first(where: { $0.value != vm.currentTarget }) ?? vm.cells[0]
        vm.currentTarget = 99

        vm.selectCell(wrongCell)
        XCTAssertEqual(vm.settings.players[0].score, 0)
        XCTAssertFalse(vm.cells.first(where: { $0.id == wrongCell.id })?.isRevealed ?? true)
    }

    func testGameEndsWhenAllCellsRevealed() {
        let vm = makeVM(boardSize: 2) // 2x2 = 4 cells
        // Reveal all cells
        for i in vm.cells.indices {
            vm.cells[i].isRevealed = true
        }
        vm.nextTurn()
        XCTAssertTrue(vm.isGameOver)
    }

    func testRandomPuzzleImageSelection_usesRandomIntAndSlices() {
        let random = MockRandomSource()
        random.ints = [3] // choose puzzle_3
        let slicer = MockPuzzleSlicer()
        let settings = GameSettings(
            boardSize: 4,
            players: makePlayers(2),
            useRandomPuzzleImage: true
        )
        let vm = GameViewModel(settings: settings, slicer: slicer, random: random)

        XCTAssertEqual(vm.puzzleImageName, "puzzle_3")
        XCTAssertEqual(slicer.lastArgs?.name, "puzzle_3")
        XCTAssertEqual(slicer.lastArgs?.size, 4)
    }

    func testDeterministicRandomSource() {
        let seeded = SeededRandomSource(seed: 123456)
        let a = seeded.int(in: 1...10)
        let b = seeded.int(in: 1...10)
        let c = seeded.int(in: 1...10)
        let seeded2 = SeededRandomSource(seed: 123456)
        XCTAssertEqual(a, seeded2.int(in: 1...10))
        XCTAssertEqual(b, seeded2.int(in: 1...10))
        XCTAssertEqual(c, seeded2.int(in: 1...10))
    }
}
