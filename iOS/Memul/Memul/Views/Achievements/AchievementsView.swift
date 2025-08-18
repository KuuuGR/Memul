//
//  AchievementsView.swift
//  Memul
//
//  Created by KuuuGR on 18/08/2025.
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject private var manager = AchievementsManager.shared
    private let columns = [GridItem(.flexible()), GridItem(.flexible())] // 2x3

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(manager.achievements) { ach in
                    AchievementCardView(achievement: ach)
                }
            }
            .padding()
        }
    }
}

struct AchievementCardView: View {
    let achievement: Achievement
    @State private var pop = false

    var body: some View {
        VStack(spacing: 8) {
            Image(achievement.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: 110)
                .saturation(achievement.isUnlocked ? 1 : 0)
                .opacity(achievement.isUnlocked ? 1 : 0.7)
                .overlay(alignment: .topTrailing) {
                    if !achievement.isUnlocked {
                        Image(systemName: "lock.fill").padding(6).foregroundStyle(.secondary)
                    }
                }
                .scaleEffect(pop ? 1.03 : 1)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: pop)

            Text(achievement.title).font(.headline).lineLimit(1)
            Text(achievement.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)

            if !achievement.isUnlocked && achievement.target > 1 {
                ProgressView(value: Double(achievement.progress), total: Double(achievement.target))
            }

            if let date = achievement.unlockedAt, achievement.isUnlocked {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06)))
        .onAppear { if achievement.isUnlocked { pop = true } }
    }
}
