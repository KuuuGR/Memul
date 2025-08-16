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

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text(NSLocalizedString("results_title", comment: "Results"))
                .font(.largeTitle.bold())
                .padding(.top)

            // Winner
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

            // Scoreboard
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

            // Buttons
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
    }
}
