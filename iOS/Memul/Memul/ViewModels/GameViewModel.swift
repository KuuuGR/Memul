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

    private let totalPuzzles = 7

    private let slicer: PuzzleSlicing
    private let random: RandomSourcing
    private let boardGen: BoardGenerating
    private var scorer: Scoring
    private let endGame: EndGameEvaluating

    var players: [Player] { settings.players }
    var currentPlayer: Player { settings.players[currentPlayerIndex] }

    init(
        settings: GameSettings,
        slicer: PuzzleSlicing = PuzzleSlicer(),
        random: RandomSourcing = SystemRandomSource(),
        boardGen: BoardGenerating = BoardGenerator(),
        scorer: Scoring = ScoreService(),
        endGame: EndGameEvaluating = EndGameEvaluator()
    ) {
        self.settings = settings
        self.slicer = slicer
        self.random = random
        self.boardGen = boardGen
        self.scorer = scorer
        self.endGame = endGame

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
        cells = boardGen.generateBoard(size: settings.boardSize)
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

        if cells[index].value == currentTarget {
            cells[index].isRevealed = true
            scorer.applyCorrectSelection(to: &settings.players, currentIndex: currentPlayerIndex)
        }

        nextTurn()
    }

    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % settings.players.count
        pickNextTarget()
        isGameOver = endGame.isGameOver(cells: cells)
    }
}
