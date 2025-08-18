//
//  AchievementsView.swift
//  Memul
//
//  Created by KuuuGR on 18/08/2025.
//

import SwiftUI

// MARK: - Safe math helpers

private extension CGFloat {
    var isGood: Bool { self.isFinite && !self.isNaN && self > 0 }
}

private func safeSize(_ candidate: CGFloat, fallback: CGFloat) -> CGFloat {
    candidate.isGood ? candidate : fallback
}

private func nonNegative(_ value: CGFloat) -> CGFloat {
    (value.isFinite && !value.isNaN) ? max(0, value) : 0
}

struct AchievementsView: View {
    @ObservedObject private var manager = AchievementsManager.shared

    // Spacing & padding (tune to taste)
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 16
    private let hSpacing: CGFloat = 14   // between columns
    private let vSpacing: CGFloat = 14   // between rows

    // Target grid (2 columns × 3 rows)
    private let columnsCount = 2
    private let rowsCount = 3

    // Minimum card height
    private let minItemHeight: CGFloat = 176

    var body: some View {
        GeometryReader { proxy in
            // Fallbacks while GeometryReader is transient (rotations/split view)
            let screen = UIScreen.main.bounds
            let safeWidth  = safeSize(proxy.size.width,  fallback: screen.width)
            let safeHeight = safeSize(proxy.size.height, fallback: screen.height)

            // Compute item sizes (non-negative, finite)
            let totalW = nonNegative(safeWidth  - (horizontalPadding * 2) - (hSpacing * CGFloat(columnsCount - 1)))
            let itemW  = floor(totalW / CGFloat(columnsCount))

            let totalH = nonNegative(safeHeight - (verticalPadding * 2) - (vSpacing * CGFloat(rowsCount - 1)))
            let tentativeH = floor(totalH / CGFloat(rowsCount))
            let itemH = max(minItemHeight, tentativeH.isGood ? tentativeH : minItemHeight)

            // Break achievements into rows of 2
            let rows = chunk(manager.achievements, into: columnsCount)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        let row = rows[rowIndex]

                        HStack(spacing: hSpacing) {
                            ForEach(0..<columnsCount, id: \.self) { col in
                                if col < row.count {
                                    AchievementCardView(
                                        achievement: row[col],
                                        width: itemW,
                                        height: itemH
                                    )
                                    .frame(width: itemW, height: itemH)
                                } else {
                                    // Keep grid alignment if odd count
                                    Color.clear
                                        .frame(width: itemW, height: itemH)
                                }
                            }
                        }

                        // HARD spacer row (cannot collapse like padding might)
                        if rowIndex != rows.count - 1 {
                            Color.clear
                                .frame(height: vSpacing)
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                // Give a subtle contrasting background so gaps are visible even with materials
                .background(Color(UIColor.systemBackground))
            }
            // Also set the scroll background to systemBackground to make gaps obvious
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle(NSLocalizedString("achievements_title", comment: ""))
    }

    // Split an array into consecutive chunks of given size
    private func chunk<T>(_ array: [T], into size: Int) -> [[T]] {
        guard size > 0 else { return [] }
        var result: [[T]] = []
        var idx = 0
        while idx < array.count {
            let end = min(idx + size, array.count)
            result.append(Array(array[idx..<end]))
            idx = end
        }
        return result
    }
}

struct AchievementCardView: View {
    let achievement: Achievement
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        VStack(spacing: 8) {
            Image(achievement.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: height * 0.4)
                .saturation(achievement.isUnlocked ? 1 : 0)
                .opacity(achievement.isUnlocked ? 1 : 0.7)
                .overlay(alignment: .topTrailing) {
                    if !achievement.isUnlocked {
                        Image(systemName: "lock.fill")
                            .padding(6)
                            .foregroundStyle(.secondary)
                    }
                }

            Text(achievement.title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(achievement.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if !achievement.isUnlocked && achievement.target > 1 {
                ProgressView(value: Double(achievement.progress), total: Double(achievement.target))
            }

            if let date = achievement.unlockedAt, achievement.isUnlocked {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: width, height: height)
        .background(.ultraThinMaterial, in: cardShape)
        .overlay(cardShape.stroke(Color.primary.opacity(0.06)))
        .clipShape(cardShape)
        .padding(.vertical, 6)   // 👈 adds space between rows
        .padding(.horizontal, 4) // 👈 adds space between columns
    }
}


#Preview {
    // Preview with synthetic data (all six achievements)
    let sample: [Achievement] = [
        Achievement(kind: .tutorialMaster,        title: "Tutorial Master",        subtitle: "Earn 1000 tutorial points", isUnlocked: false, progress: 120, target: 1000),
        Achievement(kind: .puzzleSolver,          title: "Puzzle Solver",          subtitle: "Complete 100 puzzles",      isUnlocked: true,  progress: 100, target: 100, unlockedAt: Date()),
        Achievement(kind: .explorer,              title: "Explorer",               subtitle: "Discover 50 unique images", isUnlocked: false, progress: 8,   target: 50),
        Achievement(kind: .speedrunner,           title: "Speedrunner",            subtitle: "Win in under 2 minutes",    isUnlocked: false, progress: 0,   target: 1),
        Achievement(kind: .perfectionist,         title: "Perfectionist",          subtitle: "Win with 0 mistakes",       isUnlocked: false, progress: 0,   target: 1),
        Achievement(kind: .multiplayerChampion,   title: "Multiplayer Champion",   subtitle: "Win with ≥4 players",       isUnlocked: false, progress: 0,   target: 1),
    ]

    NavigationStack {
        AchievementsView()
            .onAppear {
                Task { @MainActor in
                    AchievementsManager.shared.achievements = sample
                }
            }
    }
}
