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
            Text("Results")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.players) { player in
                    HStack {
                        Circle()
                            .fill(player.color)
                            .frame(width: 20, height: 20)
                        Text("\(player.name): \(player.score)")
                            .font(.title3)
                    }
                }
            }

            if let winner = viewModel.players.max(by: { $0.score < $1.score }) {
                Text("🏆 Winner: \(winner.name)!")
                    .font(.title2)
                    .foregroundColor(winner.color)
                    .padding(.top, 10)
            }

            Button(action: {
                viewModel.newGame()
                dismiss()
            }) {
                Text("New Game")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                dismiss()
            }) {
                Text("Close")
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
