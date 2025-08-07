import Foundation

protocol BoardGenerating {
    func generateBoard(size: Int) -> [Cell]
}

struct BoardGenerator: BoardGenerating {
    func generateBoard(size: Int) -> [Cell] {
        var result: [Cell] = []
        result.reserveCapacity(size * size)
        for row in 1...size {
            for col in 1...size {
                result.append(Cell(
                    row: row,
                    col: col,
                    value: row * col,
                    puzzlePieceRect: nil
                ))
            }
        }
        return result
    }
}
