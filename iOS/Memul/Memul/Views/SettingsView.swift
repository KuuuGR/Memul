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
            // MARK: Board Size
            Section(header: Text(NSLocalizedString("board_size", comment: ""))) {
                Stepper(value: $settings.boardSize, in: 1...maxBoardSize) {
                    Text(String(format: NSLocalizedString("board_size_value", comment: ""), settings.boardSize, settings.boardSize))
                }
            }

            // MARK: Players
            Section(header: Text(NSLocalizedString("players", comment: ""))) {
                ForEach(0..<settings.players.count, id: \.self) { index in
                    TextField(String(format: NSLocalizedString("player_n", comment: ""), index + 1),
                              text: $settings.players[index].name)
                }

                if settings.players.count < maxPlayers {
                    Button(NSLocalizedString("add_player", comment: "")) {
                        // You can rotate colors if you wish; using green as a simple default.
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

            // MARK: Puzzle
            Section(header: Text(NSLocalizedString("puzzle", comment: ""))) {
                Toggle(NSLocalizedString("use_random_puzzle", comment: ""), isOn: $settings.useRandomPuzzleImage)
                    .disabled(!settings.isPremium)
                    .opacity(settings.isPremium ? 1.0 : 0.5)
            }

            // MARK: Difficulty
            Section(header: Text(NSLocalizedString("difficulty", comment: ""))) {
                Picker(NSLocalizedString("difficulty_mode", comment: ""), selection: $settings.difficulty) {
                    Text(NSLocalizedString("difficulty_easy", comment: ""))
                        .tag(Difficulty.easy)
                    Text(NSLocalizedString("difficulty_normal", comment: ""))
                        .tag(Difficulty.normal)
                    Text(NSLocalizedString("difficulty_hard", comment: ""))
                        .tag(Difficulty.hard)
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isPremium) // Free → Easy only
                .onChange(of: settings.difficulty) { _, newValue in
                    // If premium is off, enforce Easy
                    if !settings.isPremium && newValue != .easy {
                        settings.difficulty = .easy
                    }
                }

                if !settings.isPremium {
                    Text(NSLocalizedString("difficulty_premium_hint", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // MARK: Index Labels
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

            // MARK: Turn Timer
            Section(header: Text(NSLocalizedString("turn_timer_title", comment: "Turn timer"))) {
                Picker(NSLocalizedString("turn_timer_per_turn", comment: "Per-turn limit"), selection: bindingForTurnLimit()) {
                    Text(NSLocalizedString("turn_30s", comment: "30s")).tag(Int?.some(30))
                    Text(NSLocalizedString("turn_60s", comment: "60s")).tag(Int?.some(60))
                    Text(NSLocalizedString("turn_120s", comment: "120s")).tag(Int?.some(120))
                    Text(NSLocalizedString("turn_infinity", comment: "∞")).tag(Int?.none) // nil = unlimited
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isPremium) // Free users locked to 30s

                if !settings.isPremium {
                    Text(NSLocalizedString("turn_timer_free_hint", comment: "Free version uses a fixed 30s per turn."))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // MARK: Header/UX Options
            Section(header: Text(NSLocalizedString("header_options", comment: ""))) {
                Toggle(NSLocalizedString("show_selected_coordinates_button", comment: ""), isOn: $settings.showSelectedCoordinatesButton)
            }

            // MARK: Premium Access
            Section(header: Text(NSLocalizedString("premium_access", comment: ""))) {
                Toggle(NSLocalizedString("unlock_premium", comment: ""), isOn: $settings.isPremium)
                    .onChange(of: settings.isPremium) { _, isPremium in
                        if !isPremium {
                            // Enforce free limitations when premium is turned off
                            if settings.boardSize > GameSettings.freeMaxBoardSize {
                                settings.boardSize = GameSettings.freeMaxBoardSize
                            }
                            if settings.players.count > GameSettings.freeMaxPlayers {
                                settings.players = Array(settings.players.prefix(GameSettings.freeMaxPlayers))
                            }
                            settings.useRandomPuzzleImage = false
                            settings.difficulty = .easy
                            // Lock timer back to 30s for free users
                            settings.turnTimeLimit = 30
                            // Reset index colors to defaults (non-transparent)
                            settings.indexColors = IndexColors()
                        }
                    }

                if !settings.isPremium {
                    Text(String(format: NSLocalizedString("free_limitations", comment: ""),
                                GameSettings.freeMaxBoardSize,
                                GameSettings.freeMaxPlayers))
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle(NSLocalizedString("settings_title", comment: ""))
        .onAppear {
            // Ensure free users always have 30s at view entry
            if !settings.isPremium { settings.turnTimeLimit = 30 }
            // Ensure Easy if premium is off
            if !settings.isPremium && settings.difficulty != .easy {
                settings.difficulty = .easy
            }
        }
    }

    // Premium limits (you can tune these)
    private var maxBoardSize: Int {
        settings.isPremium ? 12 : GameSettings.freeMaxBoardSize
    }

    private var maxPlayers: Int {
        settings.isPremium ? 16 : GameSettings.freeMaxPlayers
    }

    /// Binding helper to support nil (= ∞) in segmented picker.
    private func bindingForTurnLimit() -> Binding<Int?> {
        Binding<Int?>(
            get: { settings.turnTimeLimit },
            set: { newValue in
                // If not premium, force back to 30 seconds
                if !settings.isPremium {
                    settings.turnTimeLimit = 30
                } else {
                    settings.turnTimeLimit = newValue // 30/60/120 or nil (∞)
                }
            }
        )
    }
}
