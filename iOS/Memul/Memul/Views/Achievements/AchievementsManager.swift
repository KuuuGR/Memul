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

    private init(store: AchievementsStore = FileAchievementsStore()) {
        self.store = store
        if let loaded = try? store.load() {
            self.snapshot = loaded
        } else {
            self.snapshot = AchievementsSnapshot(achievements: Self.defaultAchievements())
            scheduleSave()
        }
    }

    var achievements: [Achievement] {
        get { snapshot.achievements }
        set {
            snapshot.achievements = newValue
            scheduleSave()
            objectWillChange.send()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s debounce
            guard let self else { return }
            try? self.store.save(self.snapshot)
        }
    }

    private static func defaultAchievements() -> [Achievement] {
        [
            Achievement(kind: .tutorialMaster,
                        title: NSLocalizedString("achv_tutorial_master_title", comment: "Tutorial Master"),
                        subtitle: NSLocalizedString("achv_tutorial_master_sub", comment: "Earn 1000 tutorial points"),
                        isUnlocked: false, progress: 0, target: 1000),

            Achievement(kind: .puzzleSolver,
                        title: NSLocalizedString("achv_puzzle_solver_title", comment: "Puzzle Solver"),
                        subtitle: NSLocalizedString("achv_puzzle_solver_sub", comment: "Complete 100 puzzles"),
                        isUnlocked: false, progress: 0, target: 100),

            Achievement(kind: .explorer,
                        title: NSLocalizedString("achv_explorer_title", comment: "Explorer"),
                        subtitle: NSLocalizedString("achv_explorer_sub", comment: "Discover 50 unique images"),
                        isUnlocked: false, progress: 0, target: 50),

            Achievement(kind: .speedrunner,
                        title: NSLocalizedString("achv_speedrunner_title", comment: "Speedrunner"),
                        subtitle: NSLocalizedString("achv_speedrunner_sub", comment: "Win in under 2 minutes"),
                        isUnlocked: false, progress: 0, target: 1),

            Achievement(kind: .perfectionist,
                        title: NSLocalizedString("achv_perfectionist_title", comment: "Perfectionist"),
                        subtitle: NSLocalizedString("achv_perfectionist_sub", comment: "Win with 0 mistakes"),
                        isUnlocked: false, progress: 0, target: 1),

            Achievement(kind: .multiplayerChampion,
                        title: NSLocalizedString("achv_multiplayer_champ_title", comment: "Multiplayer Champion"),
                        subtitle: NSLocalizedString("achv_multiplayer_champ_sub", comment: "Win with ≥4 players"),
                        isUnlocked: false, progress: 0, target: 1),
        ]
    }

    // MARK: - Event API

    func onTutorialScored(rightCount: Int) {
        let points = rightCount * 1 // 1 correct = 1 pkt ; increase multiply number for easier achievement
        update(.tutorialMaster) { ach in
            ach.progress = min(ach.target, ach.progress + points)
            if !ach.isUnlocked && ach.progress >= ach.target {
                ach.isUnlocked = true; ach.unlockedAt = Date()
            }
        }
    }

    func onPuzzleCompleted(puzzleId: Int?) {
        update(.puzzleSolver) { ach in
            ach.progress = min(ach.target, ach.progress + 1)
            if !ach.isUnlocked && ach.progress >= ach.target {
                ach.isUnlocked = true; ach.unlockedAt = Date()
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
                    ach.isUnlocked = true; ach.unlockedAt = Date()
                }
            }
        }
    }

    func onMultiplayerResult(winnerName: String, playersCount: Int) {
        guard playersCount >= 4 else { return }
        update(.multiplayerChampion) { ach in
            ach.progress = 1
            if !ach.isUnlocked {
                ach.isUnlocked = true; ach.unlockedAt = Date()
            }
        }
    }

    func onSpeedrun(duration: TimeInterval) {
        guard duration < 120 else { return }
        update(.speedrunner) { ach in
            ach.progress = 1
            if !ach.isUnlocked {
                ach.isUnlocked = true; ach.unlockedAt = Date()
            }
        }
    }

    func onPerfection(errors: Int) {
        guard errors == 0 else { return }
        update(.perfectionist) { ach in
            ach.progress = 1
            if !ach.isUnlocked {
                ach.isUnlocked = true; ach.unlockedAt = Date()
            }
        }
    }

    // MARK: - Helpers

    private func update(_ id: AchievementID, mutate: (inout Achievement) -> Void) {
        if let idx = achievements.firstIndex(where: { $0.kind == id }) {
            var a = achievements[idx]
            mutate(&a)
            achievements[idx] = a
        }
    }
}

// ID z nazw: "puzzle_01", "puzzle_free_07" → 1, 7
enum PuzzleIdParser {
    static func id(from name: String) -> Int? {
        let comps = name.split(separator: "_")
        guard let last = comps.last else { return nil }
        let digits = last.filter(\.isNumber)
        return Int(digits)
    }
}

