import Foundation

protocol Scoring {
    mutating func reset()
    mutating func applyCorrectSelection(to players: inout [Player], currentIndex: Int)
}

struct ScoreService: Scoring {
    mutating func reset() { /* hook for future streaks/combo */ }

    mutating func applyCorrectSelection(to players: inout [Player], currentIndex: Int) {
        guard players.indices.contains(currentIndex) else { return }
        players[currentIndex].score += 1
    }
}
