//
//  StartView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct StartView: View {
    @State private var settings = GameSettings(
        boardSize: 5,
        players: [
            Player(name: "Player 1", color: .red),
            Player(name: "Player 2", color: .blue)
        ]
    )

    @State private var isActive = false
    @State private var gameViewModel: GameViewModel?
    @State private var isShowingSettings = false
    @State private var isShowingAbout = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Memul")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button("Start Game") {
                    startGame()
                }
                .buttonStyle(.borderedProminent)

                HStack(spacing: 12) {
                    Button("Settings") {
                        isShowingSettings = true
                    }
                    .buttonStyle(.bordered)

                    Button("About") {
                        isShowingAbout = true
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $isActive) {
                if let gameViewModel = gameViewModel {
                    GameView(viewModel: gameViewModel)
                }
            }
            .navigationDestination(isPresented: $isShowingSettings) {
                SettingsView(settings: $settings)
            }
            .navigationDestination(isPresented: $isShowingAbout) {
                AboutView()
            }
        }
    }

    @MainActor
    private func startGame() {
        gameViewModel = GameViewModel(settings: settings)
        isActive = true
    }
}

#Preview {
    StartView()
}
