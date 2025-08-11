//
//  SettingsView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 04/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var settings: GameSettings

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("board_size", comment: ""))) {
                Stepper(value: $settings.boardSize, in: 1...maxBoardSize) {
                    Text(String(format: NSLocalizedString("board_size_value", comment: ""), settings.boardSize, settings.boardSize))
                }
            }

            Section(header: Text(NSLocalizedString("players", comment: ""))) {
                ForEach(0..<settings.players.count, id: \.self) { index in
                    TextField(String(format: NSLocalizedString("player_n", comment: ""), index + 1), text: $settings.players[index].name)
                }

                if settings.players.count < maxPlayers {
                    Button(NSLocalizedString("add_player", comment: "")) {
                        let newColor: Color = .green
                        settings.players.append(Player(name: "Player \(settings.players.count + 1)", color: newColor))
                    }
                }

                if settings.players.count > 1 {
                    Button(NSLocalizedString("remove_last_player", comment: ""), role: .destructive) {
                        settings.players.removeLast()
                    }
                }
            }

            Section(header: Text(NSLocalizedString("puzzle", comment: ""))) {
                Toggle(NSLocalizedString("use_random_puzzle", comment: ""), isOn: $settings.useRandomPuzzleImage)
                    .disabled(!settings.isPremium)
                    .opacity(settings.isPremium ? 1.0 : 0.5)
            }

            Section(header: Text(NSLocalizedString("index_labels", comment: ""))) {
                Toggle(NSLocalizedString("show_top_labels", comment: ""), isOn: $settings.indexVisibility.top)
                Toggle(NSLocalizedString("show_bottom_labels", comment: ""), isOn: $settings.indexVisibility.bottom)
                Toggle(NSLocalizedString("show_left_labels", comment: ""), isOn: $settings.indexVisibility.left)
                Toggle(NSLocalizedString("show_right_labels", comment: ""), isOn: $settings.indexVisibility.right)

                if settings.isPremium {
                    ColorPicker(NSLocalizedString("top_color", comment: ""), selection: $settings.indexColors.top)
                    ColorPicker(NSLocalizedString("bottom_color", comment: ""), selection: $settings.indexColors.bottom)
                    ColorPicker(NSLocalizedString("left_color", comment: ""), selection: $settings.indexColors.left)
                    ColorPicker(NSLocalizedString("right_color", comment: ""), selection: $settings.indexColors.right)
                    Button(NSLocalizedString("make_labels_transparent", comment: "")) {
                        settings.indexColors = .transparent
                    }
                } else {
                    Text(NSLocalizedString("index_labels_premium_hint", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("Turn timer")) {
                // Free: fixed 30s (disabled UI). Premium: pick 30 / 60 / 120 / ∞.
                Picker("Per-turn limit", selection: bindingForTurnLimit()) {
                    Text("30s").tag(Int?.some(30))
                    Text("60s").tag(Int?.some(60))
                    Text("120s").tag(Int?.some(120))
                    Text("∞").tag(Int?.none) // nil = unlimited
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isPremium) // free users locked to 30s
                if !settings.isPremium {
                    Text("Free version uses a fixed 30s per turn.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text(NSLocalizedString("header_options", comment: ""))) {
                Toggle(NSLocalizedString("show_selected_coordinates_button", comment: ""), isOn: $settings.showSelectedCoordinatesButton)
            }

            Section(header: Text(NSLocalizedString("premium_access", comment: ""))) {
                Toggle(NSLocalizedString("unlock_premium", comment: ""), isOn: $settings.isPremium)
                    // iOS 17+ onChange signature, fixes deprecation
                    .onChange(of: settings.isPremium) { _, isPremium in
                        if !isPremium {
                            if settings.boardSize > GameSettings.freeMaxBoardSize {
                                settings.boardSize = GameSettings.freeMaxBoardSize
                            }
                            if settings.players.count > GameSettings.freeMaxPlayers {
                                settings.players = Array(settings.players.prefix(GameSettings.freeMaxPlayers))
                            }
                            settings.useRandomPuzzleImage = false
                            settings.indexColors = IndexColors()
                            // Lock timer back to 30s for free users
                            settings.turnTimeLimit = 30
                        }
                    }

                if !settings.isPremium {
                    Text(String(format: NSLocalizedString("free_limitations", comment: ""), GameSettings.freeMaxBoardSize, GameSettings.freeMaxPlayers))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle(NSLocalizedString("settings_title", comment: ""))
        .onAppear {
            // Ensure free users always have 30s
            if !settings.isPremium { settings.turnTimeLimit = 30 }
        }
    }

    private var maxBoardSize: Int {
        settings.isPremium ? 12 : GameSettings.freeMaxBoardSize
    }

    private var maxPlayers: Int {
        settings.isPremium ? 16 : GameSettings.freeMaxPlayers
    }

    // Binding helper to support nil (= ∞) in segmented picker.
    private func bindingForTurnLimit() -> Binding<Int?> {
        Binding<Int?>(
            get: { settings.turnTimeLimit },
            set: { newValue in
                // If not premium, force back to 30
                if !settings.isPremium {
                    settings.turnTimeLimit = 30
                } else {
                    settings.turnTimeLimit = newValue // 30/60/120 or nil (∞)
                }
            }
        )
    }
}
