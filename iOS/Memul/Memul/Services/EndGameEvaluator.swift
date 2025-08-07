import Foundation

protocol EndGameEvaluating {
    func isGameOver(cells: [Cell]) -> Bool
}

struct EndGameEvaluator: EndGameEvaluating {
    func isGameOver(cells: [Cell]) -> Bool {
        cells.allSatisfy { $0.isRevealed }
    }
}
