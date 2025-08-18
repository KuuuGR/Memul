//
//  Achievement.swift
//  Memul
//
//  Created by KuuuGR on 18/08/2025.
//
import Foundation

enum AchievementID: String, Codable, CaseIterable {
    case tutorialMaster         // 01
    case puzzleSolver           // 02
    case explorer               // 03
    case speedrunner            // 04
    case perfectionist          // 05
    case multiplayerChampion    // 06
}

struct Achievement: Identifiable, Codable, Equatable {
    var id: AchievementID { kind }
    let kind: AchievementID
    var title: String
    var subtitle: String
    var isUnlocked: Bool = false
    var progress: Int = 0
    var target: Int = 0
    var unlockedAt: Date? = nil

    var assetName: String {
        switch kind {
        case .tutorialMaster:        return "Achievement01"
        case .puzzleSolver:          return "Achievement02"
        case .explorer:              return "Achievement03"
        case .speedrunner:           return "Achievement04"
        case .perfectionist:         return "Achievement05"
        case .multiplayerChampion:   return "Achievement06"
        }
    }
}

struct AchievementsSnapshot: Codable {
    var schemaVersion: Int = 1
    var achievements: [Achievement]
    var discoveredPuzzleIds: Set<Int> = []
    var puzzlesCompleted: Int = 0
}

