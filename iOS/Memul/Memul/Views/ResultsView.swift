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
        VStack(spacing: 20) {
            Text(NSLocalizedString("results_title", comment: "Results"))
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.players) { player in
                    HStack {
                        Circle()
                            .fill(player.color)
                            .frame(width: 20, height: 20)
                        Text(String(format: NSLocalizedString("player_score", comment: "%@: %d"),
                                    player.name, player.score))
                            .font(.title3)
                    }
                }
            }

            if let winner = viewModel.players.max(by: { $0.score < $1.score }) {
                Text(String(format: NSLocalizedString("winner_announcement", comment: "🏆 Winner: %@!"),
                            winner.name))
                    .font(.title2)
                    .foregroundColor(winner.color)
                    .padding(.top, 10)
            }

            Button(action: {
                viewModel.newGame()
                dismiss()
            }) {
                Text(NSLocalizedString("new_game", comment: "New Game"))
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: { dismiss() }) {
                Text(NSLocalizedString("close", comment: "Close"))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
