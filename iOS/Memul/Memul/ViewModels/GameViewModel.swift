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

    // --- Turn timer (per-turn) ---
    // Remaining seconds for the current turn. `nil` means unlimited (∞).
    @Published var timeRemaining: Int? = nil

    private var turnTimer: Timer? // fires every second while a timed turn is active
    private var isTimerPaused: Bool = false

    private let totalPuzzles = 50 //TODO: GQTODO

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

        // Initialize timer for the very first turn
        configureTimerForCurrentTurn()
    }

    deinit {
        turnTimer?.invalidate()
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
            stopTurnTimer()
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
    func selectCell(_ cell: Cell) {
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

        if isGameOver {
            stopTurnTimer()
        } else {
            configureTimerForCurrentTurn()
        }
    }

    func dismissPuzzleOverlay() {
        showPuzzleOverlay = false
        // If the game actually ended, there's nothing to resume.
        if !isGameOver {
            resumeTurnTimerIfNeeded()
        }
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
        configureTimerForCurrentTurn()
    }

    // MARK: - Turn timer helpers

    /// Sets up timer state for the current player based on settings.
    private func configureTimerForCurrentTurn() {
        // Free users always 30s; premium uses chosen limit (including ∞).
        timeRemaining = settings.turnTimeLimit
        isTimerPaused = false
        restartTurnTimerIfNeeded()
    }

    /// Start/restart the 1s ticking timer if we have a finite turn time.
    private func restartTurnTimerIfNeeded() {
        stopTurnTimer()
        guard let _ = timeRemaining else { return } // unlimited
        turnTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(turnTimer!, forMode: .common)
    }

    /// Decrement remaining time and handle timeouts.
    private func tick() {
        guard !isTimerPaused else { return }
        guard var remaining = timeRemaining else { return } // unlimited
        guard remaining > 0 else {
            // Safety: if already 0, treat as timeout
            handleTurnTimeout()
            return
        }
        remaining -= 1
        timeRemaining = remaining
        if remaining == 0 {
            handleTurnTimeout()
        }
    }

    /// On timeout we just advance to the next player without revealing anything.
    private func handleTurnTimeout() {
        stopTurnTimer()
        // As per requirements: no reveal, no score, just move on.
        currentSelection = nil
        nextTurn()
    }

    /// Pause ticking without losing remaining time.
    func pauseTurnTimer() {
        isTimerPaused = true
    }

    /// Resume ticking if finite and game not over.
    func resumeTurnTimerIfNeeded() {
        guard !isGameOver else { return }
        isTimerPaused = false
        // If we somehow lost the timer (e.g., after a modal), recreate it.
        if turnTimer == nil, timeRemaining != nil {
            restartTurnTimerIfNeeded()
        }
    }

    private func stopTurnTimer() {
        turnTimer?.invalidate()
        turnTimer = nil
    }
}
