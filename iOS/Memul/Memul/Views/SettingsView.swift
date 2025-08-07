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
    }

    private var maxBoardSize: Int {
        settings.isPremium ? 12 : GameSettings.freeMaxBoardSize
    }

    private var maxPlayers: Int {
        settings.isPremium ? 16 : GameSettings.freeMaxPlayers
    }
}
