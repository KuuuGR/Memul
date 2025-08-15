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

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(NSLocalizedString("app_title", comment: "App title on start screen"))
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Start game (programmatic so we can create the VM)
                Button(NSLocalizedString("start_game", comment: "Start game button")) {
                    startGame()
                }
                .buttonStyle(.borderedProminent)

                // Quick Practice
                VStack(spacing: 12) {
                    NavigationLink(NSLocalizedString("quick_multiply", comment: "Quick multiplication practice")) {
                        QuickPracticeView(
                            mode: .multiplication,
                            minValue: settings.multiplicationMin,
                            maxValue: settings.multiplicationMax,
                            difficulty: settings.difficulty
                        )
                        .navigationTitle(NSLocalizedString("quick_multiply", comment: ""))
                    }
                    .buttonStyle(.bordered)

                    if settings.isDivisionUnlocked {
                        NavigationLink(NSLocalizedString("quick_divide", comment: "Quick division practice")) {
                            QuickPracticeView(
                                mode: .division,
                                minValue: settings.divisionMin,
                                maxValue: settings.divisionMax,
                                difficulty: settings.difficulty
                            )
                            .navigationTitle(NSLocalizedString("quick_divide", comment: ""))
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            // no-op (future: show paywall)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                Text(NSLocalizedString("quick_divide_locked", comment: "Locked division"))
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(true)
                        .opacity(0.6)
                    }
                }

                // Tutorial
                NavigationLink(NSLocalizedString("tutorial", comment: "Open tutorial")) {
                    TutorialView()
                        .navigationTitle(NSLocalizedString("tutorial_title", comment: ""))
                }
                .buttonStyle(.bordered)

                // Settings / About
                HStack(spacing: 12) {
                    NavigationLink(NSLocalizedString("settings", comment: "Open settings")) {
                        SettingsView(settings: $settings)
                            .navigationTitle(NSLocalizedString("settings_title", comment: ""))
                    }
                    .buttonStyle(.bordered)

                    NavigationLink(NSLocalizedString("about", comment: "Open about")) {
                        AboutView()
                            .navigationTitle(NSLocalizedString("ab_navigation_title", comment: ""))
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding()
            // Destination for programmatic "Start Game"
            .navigationDestination(isPresented: $isActive) {
                if let gameViewModel = gameViewModel {
                    GameView(viewModel: gameViewModel)
                }
            }
        }
    }

    /// Starts a new game safely on the main actor
    @MainActor
    private func startGame() {
        gameViewModel = GameViewModel(settings: settings)
        isActive = true
    }
}

#Preview {
    NavigationStack { StartView() }
}
