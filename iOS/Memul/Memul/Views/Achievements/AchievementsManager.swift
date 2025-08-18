//
//  AchievementsManager.swift
//  Memul
//
//  Created by KuuuGR on 18/08/2025.
//

import Foundation
import Combine

@MainActor
final class AchievementsManager: ObservableObject {
    static let shared = AchievementsManager()

    @Published private(set) var snapshot: AchievementsSnapshot
    private let store: AchievementsStore
    private var saveTask: Task<Void, Never>? = nil

    // MARK: - Init

    private init(store: AchievementsStore = FileAchievementsStore()) {
        self.store = store

        // Load snapshot if present, otherwise build defaults
        if let snap = try? store.load() {
            self.snapshot = snap
            relocalizeAll()
            scheduleSave()
        } else {
            self.snapshot = AchievementsSnapshot(achievements: Self.defaultAchievements())
            scheduleSave()
        }
    }

    // MARK: - Public accessor

    var achievements: [Achievement] {
        get { snapshot.achievements }
        set {
            snapshot.achievements = newValue
            scheduleSave()
            objectWillChange.send()
        }
    }

    // MARK: - Persistence debounce

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s debounce
            guard let self else { return }
            try? self.store.save(self.snapshot)
        }
    }

    // MARK: - Defaults (localized at creation time)

    private static func defaultAchievements() -> [Achievement] {
        [
            Achievement(kind: .tutorialMaster,
                        title: loc("achv_tutorial_master_title", "Tutorial Master"),
                        subtitle: loc("achv_tutorial_master_sub", "Earn 1000 tutorial points"),
                        isUnlocked: false, progress: 0, target: 1000),

            Achievement(kind: .puzzleSolver,
                        title: loc("achv_puzzle_solver_title", "Puzzle Solver"),
                        subtitle: loc("achv_puzzle_solver_sub", "Complete 100 puzzles"),
                        isUnlocked: false, progress: 0, target: 100),

            Achievement(kind: .explorer,
                        title: loc("achv_explorer_title", "Explorer"),
                        subtitle: loc("achv_explorer_sub", "Discover 50 unique images"),
                        isUnlocked: false, progress: 0, target: 50),

            Achievement(kind: .speedrunner,
                        title: loc("achv_speedrunner_title", "Speedrunner"),
                        subtitle: loc("achv_speedrunner_sub", "Win in under 2 minutes"),
                        isUnlocked: false, progress: 0, target: 1),

            Achievement(kind: .perfectionist,
                        title: loc("achv_perfectionist_title", "Perfectionist"),
                        subtitle: loc("achv_perfectionist_sub", "Win with 0 mistakes"),
                        isUnlocked: false, progress: 0, target: 1),

            Achievement(kind: .multiplayerChampion,
                        title: loc("achv_multiplayer_champ_title", "Multiplayer Champion"),
                        subtitle: loc("achv_multiplayer_champ_sub", "Win with ≥4 players"),
                        isUnlocked: false, progress: 0, target: 1),
        ]
    }

    // MARK: - Re-localization

    /// Re-applies localized title/subtitle for all achievements based on their kind.
    /// This fixes stale persisted strings if translations changed or were added later.
    private func relocalizeAll() {
        snapshot.achievements = snapshot.achievements.map { a in
            var b = a
            bindLocalizedTitles(&b)
            return b
        }
    }

    /// Localizes a single achievement’s title/subtitle according to its kind.
    private func bindLocalizedTitles(_ a: inout Achievement) {
        switch a.kind {
        case .tutorialMaster:
            a.title = Self.loc("achv_tutorial_master_title", "Tutorial Master")
            a.subtitle = Self.loc("achv_tutorial_master_sub", "Earn 1000 tutorial points")
        case .puzzleSolver:
            a.title = Self.loc("achv_puzzle_solver_title", "Puzzle Solver")
            a.subtitle = Self.loc("achv_puzzle_solver_sub", "Complete 100 puzzles")
        case .explorer:
            a.title = Self.loc("achv_explorer_title", "Explorer")
            a.subtitle = Self.loc("achv_explorer_sub", "Discover 50 unique images")
        case .speedrunner:
            a.title = Self.loc("achv_speedrunner_title", "Speedrunner")
            a.subtitle = Self.loc("achv_speedrunner_sub", "Win in under 2 minutes")
        case .perfectionist:
            a.title = Self.loc("achv_perfectionist_title", "Perfectionist")
            a.subtitle = Self.loc("achv_perfectionist_sub", "Win with 0 mistakes")
        case .multiplayerChampion:
            a.title = Self.loc("achv_multiplayer_champ_title", "Multiplayer Champion")
            a.subtitle = Self.loc("achv_multiplayer_champ_sub", "Win with ≥4 players")
        }
    }

    /// Small helper that reads from the main bundle with a safe fallback.
    private static func loc(_ key: String, _ fallback: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: "")
    }

    // MARK: - Event API

    func onTutorialScored(rightCount: Int) {
        // Adjust multiplier here if desired
        let points = rightCount * 1
        update(.tutorialMaster) { ach in
            ach.progress = min(ach.target, ach.progress + points)
            if !ach.isUnlocked && ach.progress >= ach.target {
                ach.isUnlocked = true
                ach.unlockedAt = Date()
            }
        }
    }

    func onPuzzleCompleted(puzzleId: Int?) {
        update(.puzzleSolver) { ach in
            ach.progress = min(ach.target, ach.progress + 1)
            if !ach.isUnlocked && ach.progress >= ach.target {
                ach.isUnlocked = true
                ach.unlockedAt = Date()
            }
        }
        snapshot.puzzlesCompleted += 1
        scheduleSave()
    }

    func onImageDiscovered(puzzleId: Int) {
        if snapshot.discoveredPuzzleIds.insert(puzzleId).inserted {
            update(.explorer) { ach in
                ach.progress = min(ach.target, snapshot.discoveredPuzzleIds.count)
                if !ach.isUnlocked && ach.progress >= ach.target {
                    ach.isUnlocked = true
                    ach.unlockedAt = Date()
                }
            }
        }
    }

    func onMultiplayerResult(winnerName: String, playersCount: Int) {
        guard playersCount >= 4 else { return }
        update(.multiplayerChampion) { ach in
            ach.progress = 1
            if !ach.isUnlocked {
                ach.isUnlocked = true
                ach.unlockedAt = Date()
            }
        }
    }

    func onSpeedrun(duration: TimeInterval) {
        guard duration < 120 else { return }
        update(.speedrunner) { ach in
            ach.progress = 1
            if !ach.isUnlocked {
                ach.isUnlocked = true
                ach.unlockedAt = Date()
            }
        }
    }

    func onPerfection(errors: Int) {
        guard errors == 0 else { return }
        update(.perfectionist) { ach in
            ach.progress = 1
            if !ach.isUnlocked {
                ach.isUnlocked = true
                ach.unlockedAt = Date()
            }
        }
    }

    // MARK: - Helpers

    private func update(_ id: AchievementID, mutate: (inout Achievement) -> Void) {
        if let idx = achievements.firstIndex(where: { $0.kind == id }) {
            var a = achievements[idx]
            mutate(&a)
            // Keep titles current in case language changed between sessions
            bindLocalizedTitles(&a)
            achievements[idx] = a
        }
    }
}

// MARK: - PuzzleIdParser

/// IDs from names: "puzzle_01", "puzzle_free_07" → 1, 7
enum PuzzleIdParser {
    static func id(from name: String) -> Int? {
        let comps = name.split(separator: "_")
        guard let last = comps.last else { return nil }
        let digits = last.filter(\.isNumber)
        return Int(digits)
    }
}
