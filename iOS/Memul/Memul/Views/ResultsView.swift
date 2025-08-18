//
//  ResultsView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct ResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GameViewModel

    // Prevent double-firing achievement events when the sheet reappears
    @State private var didFireAchievements = false

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text(NSLocalizedString("results_title", comment: "Results"))
                .font(.largeTitle.bold())
                .padding(.top)

            // Winner highlight
            if let winner = viewModel.players.max(by: { $0.score < $1.score }) {
                HStack {
                    Text("🏆")
                        .font(.system(size: 40))
                    Text(String(format: NSLocalizedString("winner_announcement", comment: "🏆 Winner: %@!"),
                                winner.name))
                        .font(.title2.bold())
                        .foregroundColor(winner.color)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(winner.color.opacity(0.15))
                )
            }

            // Scoreboard list
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("total_points", comment: "Total Points"))
                    .font(.headline)
                    .padding(.bottom, 4)
                ForEach(viewModel.players.sorted(by: { $0.score > $1.score })) { player in
                    HStack {
                        Circle()
                            .fill(player.color)
                            .frame(width: 20, height: 20)
                        Text(player.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(player.score)")
                            .bold()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            // Actions
            VStack(spacing: 12) {
                Button {
                    viewModel.newGame()
                    dismiss()
                } label: {
                    Text(NSLocalizedString("new_game", comment: "New Game"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button { dismiss() } label: {
                    Text(NSLocalizedString("close", comment: "Close"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .onAppear {
            // Fire achievements exactly once per presentation
            guard !didFireAchievements else { return }
            didFireAchievements = true

            // Only process if the game truly concluded
            guard viewModel.isGameOver else { return }

            // Speedrunner: win under 120s
            AchievementsManager.shared.onSpeedrun(duration: viewModel.gameDuration)

            // Perfectionist: no wrong answers
            AchievementsManager.shared.onPerfection(errors: viewModel.wrongAnswers)

            // Puzzle Solver (+1 completed) and Explorer (unique image IDs)
            if let name = viewModel.puzzleImageName,
               let id = PuzzleIdParser.id(from: name) {
                AchievementsManager.shared.onPuzzleCompleted(puzzleId: id)
                AchievementsManager.shared.onImageDiscovered(puzzleId: id)
            } else {
                // Fall back if no parseable image id
                AchievementsManager.shared.onPuzzleCompleted(puzzleId: nil)
            }

            // Multiplayer Champion: winner with ≥4 total players
            if viewModel.players.count >= 4,
               let winner = viewModel.players.max(by: { $0.score < $1.score }) {
                AchievementsManager.shared.onMultiplayerResult(
                    winnerName: winner.name,
                    playersCount: viewModel.players.count
                )
            }
        }
    }
}
