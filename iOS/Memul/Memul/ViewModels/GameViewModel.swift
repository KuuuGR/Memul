//
//  GameViewModel.swift
//  Memul
//

import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var settings: GameSettings
    @Published var cells: [Cell] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var currentTarget: Int = 1
    @Published var isGameOver: Bool = false

    // Puzzle
    @Published var puzzleImageName: String? = nil
    @Published var puzzlePieces: [[Image]] = []   // Pre-sliced pieces for current board

    // Coordinates UX (first tap highlights the coordinates)
    @Published var currentSelection: (row: Int, col: Int)? = nil

    // End-game overlay visibility (full puzzle)
    @Published var showPuzzleOverlay: Bool = false

    // Per-turn timer
    @Published var timeRemaining: Int? = nil
    private var turnTimer: Timer?
    private var isTimerPaused: Bool = false

    // Static cache: reuse slices per (imageName, boardSize)
    private static var sliceCache: [String: [[Image]]] = [:]

    // MARK: - Convenience
    var players: [Player] { settings.players }
    var currentPlayer: Player { settings.players[currentPlayerIndex] }

    // MARK: - Achievements helpers (new)
    /// Number of wrong selections made across the whole game.
    @Published var wrongAnswers: Int = 0

    /// Start timestamp of the current game session.
    private var gameStartAt: Date = Date()

    /// Elapsed time since game start. Used to evaluate "Speedrunner".
    var gameDuration: TimeInterval { Date().timeIntervalSince(gameStartAt) }

    // MARK: - Init / Deinit
    init(settings: GameSettings) {
        self.settings = settings

        // Initialize achievement counters/timers
        self.gameStartAt = Date()
        self.wrongAnswers = 0

        selectPuzzleImage()
        generateBoard()
        pickNextTarget()

        showPuzzleOverlay = false
        currentSelection = nil

        configureTimerForCurrentTurn()
    }

    deinit {
        turnTimer?.invalidate()
    }

    // MARK: - Puzzle Selection & Slicing
    private func selectPuzzleImage() {
        // If user turned puzzles off → no image
        guard settings.puzzlesEnabled else {
            puzzleImageName = nil
            puzzlePieces = []
            return
        }

        // Build candidate names based on premium access
        var candidates: [String] = []

        // Free pack (always included if > 0)
        if PuzzlePacks.freeCount > 0 {
            let free = (1...PuzzlePacks.freeCount).map { String(format: "puzzle_free_%02d", $0) }
            candidates.append(contentsOf: free)
        }

        // Premium pack (only for premium users)
        if settings.isPremium, PuzzlePacks.premiumCount > 0 {
            let premium = (1...PuzzlePacks.premiumCount).map { String(format: "puzzle_%02d", $0) }
            candidates.append(contentsOf: premium)
        }

        // If nothing to choose → disable puzzle safely
        guard let chosen = candidates.randomElement() else {
            puzzleImageName = nil
            puzzlePieces = []
            return
        }

        puzzleImageName = chosen
        preparePuzzlePieces()

        // NOTE: If you want to count "Explorer" on selection (not only at Results),
        // you can send an event here:
        // if let id = PuzzleIdParser.id(from: chosen) {
        //     AchievementsManager.shared.onImageDiscovered(puzzleId: id)
        // }
    }

    private func preparePuzzlePieces() {
        guard let name = puzzleImageName else {
            puzzlePieces = []
            return
        }

        let key = "\(name)_\(settings.boardSize)"
        if let cached = GameViewModel.sliceCache[key] {
            puzzlePieces = cached
            return
        }

        guard let uiImage = UIImage(named: name) else {
            puzzlePieces = []
            return
        }

        let size = settings.boardSize
        let imageSize = uiImage.size
        let pieceW = imageSize.width  / CGFloat(size)
        let pieceH = imageSize.height / CGFloat(size)

        var pieces: [[Image]] = []
        for r in 0..<size {
            var row: [Image] = []
            for c in 0..<size {
                let rect = CGRect(
                    x: CGFloat(c) * pieceW,
                    y: CGFloat(r) * pieceH,
                    width: pieceW,
                    height: pieceH
                ).integral

                if let cg = uiImage.cgImage?.cropping(to: rect) {
                    row.append(Image(uiImage: UIImage(cgImage: cg)))
                } else {
                    row.append(Image(systemName: "questionmark.square"))
                }
            }
            pieces.append(row)
        }

        GameViewModel.sliceCache[key] = pieces
        puzzlePieces = pieces
    }

    /// Optional public API to clear global slice cache (e.g., from Settings)
    static func clearPuzzleCache() {
        sliceCache.removeAll()
    }

    // MARK: - Board
    func generateBoard() {
        cells.removeAll(keepingCapacity: true)
        let n = settings.boardSize
        for r in 1...n {
            for c in 1...n {
                cells.append(Cell(row: r, col: c, value: r * c))
            }
        }
    }

    // MARK: - Target & Turns
    func pickNextTarget() {
        let remaining = cells.filter { !$0.isRevealed }
        let possible = Array(Set(remaining.map { $0.value }))
        guard let next = possible.randomElement() else {
            // No targets left → game over
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

    // First tap only marks coordinates
    func firstTap(row: Int, col: Int) {
        guard !isGameOver else { return }
        currentSelection = (row, col)
    }

    // Second tap or a dedicated confirm button submits the selection
    func submitCurrentSelection() {
        guard let sel = currentSelection,
              let cell = cells.first(where: { $0.row == sel.row && $0.col == sel.col })
        else { return }
        selectCell(cell)
    }

    func selectCell(_ cell: Cell) {
        guard let i = cells.firstIndex(where: { $0.id == cell.id }),
              !cells[i].isRevealed else {
            finishTurn()
            return
        }

        if cells[i].value == currentTarget {
            // Correct: always +1
            cells[i].isRevealed = true
            settings.players[currentPlayerIndex].score += 1
        } else {
            // Wrong: apply penalty per difficulty (also increments wrongAnswers)
            applyPenaltyForWrongAnswer()
        }

        finishTurn()
    }

    private func applyPenaltyForWrongAnswer() {
        // Count a wrong answer for the whole game (used by "Perfectionist")
        wrongAnswers += 1

        switch settings.difficulty {
        case .easy:
            // No score penalty on Easy
            break
        case .normal:
            // -1, clamped at 0
            let s = settings.players[currentPlayerIndex].score
            settings.players[currentPlayerIndex].score = max(0, s - 1)
        case .hard:
            // -1, can go negative
            settings.players[currentPlayerIndex].score -= 1
        }
    }

    private func finishTurn() {
        currentSelection = nil
        nextTurn()
    }

    func nextTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % settings.players.count
        pickNextTarget()

        if cells.allSatisfy({ $0.isRevealed }) {
            isGameOver = true
            showPuzzleOverlay = true
            stopTurnTimer()
        } else {
            configureTimerForCurrentTurn()
        }
    }

    func dismissPuzzleOverlay() {
        showPuzzleOverlay = false
        if !isGameOver { resumeTurnTimerIfNeeded() }
    }

    func newGame() {
        // Reset state
        currentPlayerIndex = 0
        currentTarget = 1
        isGameOver = false
        showPuzzleOverlay = false
        currentSelection = nil

        // Reset achievement counters
        wrongAnswers = 0
        gameStartAt = Date()

        // Reset scores
        for i in settings.players.indices {
            settings.players[i].score = 0
        }

        selectPuzzleImage()
        generateBoard()
        pickNextTarget()
        configureTimerForCurrentTurn()
    }

    // MARK: - Turn Timer
    /// Configure timer for the current player based on settings.
    private func configureTimerForCurrentTurn() {
        timeRemaining = settings.turnTimeLimit
        isTimerPaused = false
        restartTurnTimerIfNeeded()
    }

    /// Start or restart the 1s ticking timer if timeRemaining is finite.
    private func restartTurnTimerIfNeeded() {
        stopTurnTimer()
        guard timeRemaining != nil else { return } // unlimited
        turnTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let t = turnTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    /// Decrement remaining time and handle timeouts.
    private func tick() {
        guard !isTimerPaused else { return }
        guard var remaining = timeRemaining else { return } // unlimited
        guard remaining > 0 else {
            handleTurnTimeout()
            return
        }
        remaining -= 1
        timeRemaining = remaining
        if remaining == 0 { handleTurnTimeout() }
    }

    private func handleTurnTimeout() {
        stopTurnTimer()
        // No reveal, no score; just advance
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
