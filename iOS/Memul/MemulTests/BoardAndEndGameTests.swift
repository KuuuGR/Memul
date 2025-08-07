import XCTest
@testable import Memul

final class BoardAndEndGameTests: XCTestCase {

    func testBoardGeneratorProducesExpectedCells() {
        let gen: BoardGenerating = BoardGenerator()
        let cells = gen.generateBoard(size: 3)

        XCTAssertEqual(cells.count, 9)
        // Check a few coordinates
        func valueAt(_ r: Int, _ c: Int) -> Int? {
            cells.first(where: { $0.row == r && $0.col == c })?.value
        }
        XCTAssertEqual(valueAt(1, 1), 1)
        XCTAssertEqual(valueAt(2, 3), 6)
        XCTAssertEqual(valueAt(3, 3), 9)
    }

    func testEndGameEvaluatorDetectsAllRevealed() {
        let gen = BoardGenerator()
        var cells = gen.generateBoard(size: 2) // 4 cells
        let evaluator = EndGameEvaluator()

        XCTAssertFalse(evaluator.isGameOver(cells: cells))

        for i in cells.indices { cells[i].isRevealed = true }
        XCTAssertTrue(evaluator.isGameOver(cells: cells))
    }
}
