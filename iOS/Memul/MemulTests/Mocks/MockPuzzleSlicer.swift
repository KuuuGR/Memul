import SwiftUI
@testable import Memul

final class MockPuzzleSlicer: PuzzleSlicing {
    var lastArgs: (name: String, size: Int)?
    var result: [[Image]] = []
    func slice(imageNamed name: String, grid size: Int) -> [[Image]] {
        lastArgs = (name, size)
        return result
    }
}
