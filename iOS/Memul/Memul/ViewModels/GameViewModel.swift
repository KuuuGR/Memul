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

    // Coordinates UX
    // The currently highlighted (first tap) coordinates, always visible when enabled in settings.
    // Reset on turn change and at new game start.
    @Published var currentSelection: (row: Int, col: Int)? = nil

    // End-game overlay visibility
    @Published var showPuzzleOverlay: Bool = false

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
        showPuzzleOverlay = false
        currentSelection = nil // ensure it shows empty at game start
    }

    private func selectPuzzleImage() {
        if settings.useRandomPuzzleImage {
            let index = random.int(in: 1...totalPuzzles)
            puzzleImageName = "puzzle_\(index)"
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
            showPuzzleOverlay = true
            return
        }
        currentTarget = next
    }

    func isCorrectSelection(_ cell: Cell) -> Bool {
        cell.value == currentTarget
    }

    // First tap → set highlight + coordinates only (do not answer yet)
    func firstTap(row: Int, col: Int) {
        guard !isGameOver else { return }
        currentSelection = (row, col)
    }

    // Second tap or pressing the coordinates button → submit answer
    func submitCurrentSelection() {
        guard let sel = currentSelection else { return }
        guard let cell = cells.first(where: { $0.row == sel.row && $0.col == sel.col }) else { return }
        selectCell(cell)
    }

    // Internal selection handling (called by submitCurrentSelection())
    private func selectCell(_ cell: Cell) {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }),
              !cells[index].isRevealed else {
            // Already revealed or missing: still advance turn as per your original logic
            finishTurn()
            return
        }

        if cells[index].value == currentTarget {
            cells[index].isRevealed = true
            scorer.applyCorrectSelection(to: &settings.players, currentIndex: currentPlayerIndex)
        }

        finishTurn()
    }

    private func finishTurn() {
        // Clear the coordinates display for next player
        currentSelection = nil
        nextTurn()
    }

    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % settings.players.count
        pickNextTarget()
        isGameOver = endGame.isGameOver(cells: cells)
        showPuzzleOverlay = isGameOver
    }

    func dismissPuzzleOverlay() {
        showPuzzleOverlay = false
    }

    func newGame() {
        currentPlayerIndex = 0
        currentTarget = 1
        isGameOver = false
        showPuzzleOverlay = false
        currentSelection = nil
        for i in settings.players.indices {
            settings.players[i].score = 0
        }
        selectPuzzleImage()
        generateBoard()
        pickNextTarget()
    }
}
