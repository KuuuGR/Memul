//
//  GameSettings+Persistence.swift
//  Memul
//
//  Safe persistence without making GameSettings Codable.
//  We serialize a lightweight DTO and convert back.
//


import Foundation
import SwiftUI
import UIKit

// MARK: - Public API

extension GameSettings {
    private static let storageKey = "GameSettings.v1"

    /// Load settings from UserDefaults, or return fresh defaults.
    static func load() -> GameSettings {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let dto = try? JSONDecoder().decode(PersistedSettings.self, from: data)
        else {
            return GameSettings() // your defaults
        }
        return dto.materializeDefaultsFallback()
    }

    /// Save current settings to UserDefaults.
    func save() {
        let dto = PersistedSettings(from: self)
        if let data = try? JSONEncoder().encode(dto) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - DTOs (Codable)

private struct PersistedSettings: Codable {
    // Core
    var boardSize: Int
    var puzzlesEnabled: Bool
    var isPremium: Bool

    // Difficulty & timer
    var difficulty: String                 // "easy" | "normal" | "hard"
    var turnTimeLimit: Int?                // nil = ∞

    // Quick Practice
    var multiplicationMin: Int
    var multiplicationMax: Int
    var isDivisionUnlocked: Bool
    var divisionMin: Int
    var divisionMax: Int

    // Index labels
    var enableIndexCustomization: Bool
    var indexVisibility: PersistedVisibility
    var indexColors: PersistedColors

    // Players
    var players: [PersistedPlayer]

    init(from s: GameSettings) {
        self.boardSize = s.boardSize
        self.puzzlesEnabled = s.puzzlesEnabled
        self.isPremium = s.isPremium

        self.difficulty = s.difficulty.persistenceKey
        self.turnTimeLimit = s.turnTimeLimit

        self.multiplicationMin = s.multiplicationMin
        self.multiplicationMax = s.multiplicationMax
        self.isDivisionUnlocked = s.isDivisionUnlocked
        self.divisionMin = s.divisionMin
        self.divisionMax = s.divisionMax

        self.enableIndexCustomization = s.enableIndexCustomization
        self.indexVisibility = .init(from: s.indexVisibility)
        self.indexColors = .init(from: s.indexColors)

        self.players = s.players.map { .init(name: $0.name, colorHex: $0.color.hexARGB) }
    }

    /// Build a full GameSettings using current app defaults as fallback.
    func materializeDefaultsFallback() -> GameSettings {
        var s = GameSettings() // start from your current defaults

        // Core
        s.boardSize = boardSize
        s.puzzlesEnabled = puzzlesEnabled
        s.isPremium = isPremium

        // Difficulty & timer
        s.difficulty = Difficulty(fromPersistenceKey: difficulty) ?? s.difficulty
        s.turnTimeLimit = turnTimeLimit

        // Quick Practice
        s.multiplicationMin = multiplicationMin
        s.multiplicationMax = multiplicationMax
        s.isDivisionUnlocked = isDivisionUnlocked
        s.divisionMin = divisionMin
        s.divisionMax = divisionMax

        // Index labels
        s.enableIndexCustomization = enableIndexCustomization
        s.indexVisibility = indexVisibility.materialize(defaults: s.indexVisibility)
        s.indexColors = indexColors.materialize(defaults: s.indexColors)

        // Players
        s.players = players.map { Player(name: $0.name, color: Color(hexARGB: $0.colorHex) ?? .green) }

        return s
    }
}

private struct PersistedPlayer: Codable {
    var name: String
    var colorHex: String
}

private struct PersistedVisibility: Codable {
    var top: Bool
    var bottom: Bool
    var left: Bool
    var right: Bool

    init(from v: IndexVisibility) {
        self.top = v.top
        self.bottom = v.bottom
        self.left = v.left
        self.right = v.right
    }

    func materialize(defaults: IndexVisibility) -> IndexVisibility {
        var v = defaults
        v.top = top
        v.bottom = bottom
        v.left = left
        v.right = right
        return v
    }
}

private struct PersistedColors: Codable {
    var top: String
    var bottom: String
    var left: String
    var right: String

    init(from c: IndexColors) {
        self.top = c.top.hexARGB
        self.bottom = c.bottom.hexARGB
        self.left = c.left.hexARGB
        self.right = c.right.hexARGB
    }

    func materialize(defaults: IndexColors) -> IndexColors {
        var c = defaults
        c.top = Color(hexARGB: top) ?? c.top
        c.bottom = Color(hexARGB: bottom) ?? c.bottom
        c.left = Color(hexARGB: left) ?? c.left
        c.right = Color(hexARGB: right) ?? c.right
        return c
    }
}

// MARK: - Color <-> Hex helpers

private extension Color {
    /// ARGB hex like "#FF112233" (alpha, red, green, blue)
    var hexARGB: String {
        #if os(iOS)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let R = UInt8(clamp01(r) * 255)
        let G = UInt8(clamp01(g) * 255)
        let B = UInt8(clamp01(b) * 255)
        let A = UInt8(clamp01(a) * 255)
        return String(format: "#%02X%02X%02X%02X", A, R, G, B)
        #else
        return "#FFFFFFFF"
        #endif
    }

    init?(hexARGB: String) {
        let s = hexARGB.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard s.hasPrefix("#") else { return nil }
        let hex = String(s.dropFirst())
        guard hex.count == 8, let v = UInt32(hex, radix: 16) else { return nil }
        let A = Double((v & 0xFF00_0000) >> 24) / 255.0
        let R = Double((v & 0x00FF_0000) >> 16) / 255.0
        let G = Double((v & 0x0000_FF00) >> 8)  / 255.0
        let B = Double(v & 0x0000_00FF)        / 255.0
        self = Color(.sRGB, red: R, green: G, blue: B, opacity: A)
    }
}

private func clamp01(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }

// MARK: - Difficulty persistence helpers

private extension Difficulty {
    var persistenceKey: String {
        switch self {
        case .easy: return "easy"
        case .normal: return "normal"
        case .hard: return "hard"
        @unknown default: return "easy"
        }
    }

    init?(fromPersistenceKey key: String) {
        switch key.lowercased() {
        case "easy": self = .easy
        case "normal": self = .normal
        case "hard": self = .hard
        default: return nil
        }
    }
}
