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
    @State private var isShowingTutorial = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(NSLocalizedString("app_title", comment: "App title on start screen"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button(NSLocalizedString("start_game", comment: "Start game button")) {
                    startGame()
                }
                .buttonStyle(.borderedProminent)

                Button(NSLocalizedString("tutorial", comment: "Open tutorial")) {
                    isShowingTutorial = true
                }
                .buttonStyle(.bordered)

                HStack(spacing: 12) {
                    Button(NSLocalizedString("settings", comment: "Open settings")) {
                        isShowingSettings = true
                    }
                    .buttonStyle(.bordered)

                    Button(NSLocalizedString("about", comment: "Open about")) {
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
            .navigationDestination(isPresented: $isShowingTutorial) {
                TutorialView()
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
