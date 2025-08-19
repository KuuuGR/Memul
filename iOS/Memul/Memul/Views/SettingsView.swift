//
//  SettingsView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 04/08/2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var settings: GameSettings

    // Use a single sheet with an enum to avoid double-present issues
    private enum ActiveSheet: Identifiable {
        case paywall
        case privacy
        case terms
        var id: String { String(describing: self) }
    }
    @State private var activeSheet: ActiveSheet?

    // MARK: - Body
    var body: some View {
        Form {
            // MARK: Board Size
            Section(header: Text(NSLocalizedString("board_size", comment: ""))) {
                Stepper(
                    value: $settings.boardSize,
                    in: boardRange
                ) {
                    Text(String(
                        format: NSLocalizedString("board_size_value", comment: ""),
                        settings.boardSize, settings.boardSize
                    ))
                }
            }

            // MARK: Players
            Section(header: Text(NSLocalizedString("players", comment: ""))) {
                ForEach(0..<settings.players.count, id: \.self) { index in
                    TextField(
                        String(format: NSLocalizedString("player_n", comment: ""), index + 1),
                        text: $settings.players[index].name
                    )
                }

                if settings.players.count < maxPlayers {
                    Button(NSLocalizedString("add_player", comment: "")) {
                        let newColor: Color = .green
                        settings.players.append(
                            Player(name: "Player \(settings.players.count + 1)", color: newColor)
                        )
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
                Toggle(
                    NSLocalizedString("puzzle_enable", comment: "Show puzzle under grid"),
                    isOn: $settings.puzzlesEnabled
                )

                if settings.isPremium {
                    Text(NSLocalizedString("puzzle_premium_info", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(NSLocalizedString("puzzle_free_info", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // MARK: Difficulty
            Section(header: Text(NSLocalizedString("difficulty", comment: ""))) {
                Picker(NSLocalizedString("difficulty_mode", comment: ""), selection: $settings.difficulty) {
                    Text(NSLocalizedString("difficulty_easy", comment: "")).tag(Difficulty.easy)
                    Text(NSLocalizedString("difficulty_normal", comment: "")).tag(Difficulty.normal)
                    Text(NSLocalizedString("difficulty_hard", comment: "")).tag(Difficulty.hard)
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isPremium) // Free → Easy only
                .onChange(of: settings.difficulty) { _, newValue in
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

            // MARK: Quick practice
            Section(header: Text(NSLocalizedString("quick_practice", comment: ""))) {
                // Multiplication range (always available)
                Stepper {
                    Text(String(
                        format: NSLocalizedString("range_multiplication", comment: "Multiplication range"),
                        settings.multiplicationMin, settings.multiplicationMax
                    ))
                } onIncrement: {
                    settings.multiplicationMax = min(settings.multiplicationMax + 1, 20)
                } onDecrement: {
                    if settings.multiplicationMin < settings.multiplicationMax {
                        settings.multiplicationMax = max(settings.multiplicationMin, settings.multiplicationMax - 1)
                    } else {
                        settings.multiplicationMin = max(0, settings.multiplicationMin - 1)
                    }
                }

                // Unlock Division (premium-gated, auto-unlock on premium)
                Toggle(NSLocalizedString("unlock_division", comment: ""), isOn: $settings.isDivisionUnlocked)
                    .disabled(!settings.isPremium)
                    .opacity(settings.isPremium ? 1.0 : 0.5)
                    .onChange(of: settings.isPremium) { _, isPremium in
                        settings.isDivisionUnlocked = isPremium
                    }

                // Division range (only visible when unlocked)
                if settings.isDivisionUnlocked {
                    Stepper {
                        Text(String(
                            format: NSLocalizedString("range_division", comment: "Division range"),
                            settings.divisionMin, settings.divisionMax
                        ))
                    } onIncrement: {
                        settings.divisionMax = min(settings.divisionMax + 1, 20)
                    } onDecrement: {
                        if settings.divisionMin < settings.divisionMax {
                            settings.divisionMax = max(settings.divisionMin, settings.divisionMax - 1)
                        } else {
                            settings.divisionMin = max(1, settings.divisionMin - 1)
                        }
                    }

                    Text(NSLocalizedString("division_note", comment: "Division note"))
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text(NSLocalizedString("division_premium_hint", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // MARK: Index Labels
            Section(header: Text(NSLocalizedString("index_labels", comment: ""))) {
                Toggle(NSLocalizedString("index_customize", comment: ""), isOn: $settings.enableIndexCustomization)
                    .disabled(!settings.isPremium)
                    .opacity(settings.isPremium ? 1.0 : 0.5)
                    .onChange(of: settings.isPremium) { _, isPremium in
                        if !isPremium { settings.enableIndexCustomization = false }
                    }

                if settings.isPremium && settings.enableIndexCustomization {
                    Group {
                        Toggle(NSLocalizedString("show_top_labels", comment: ""), isOn: $settings.indexVisibility.top)
                        Toggle(NSLocalizedString("show_bottom_labels", comment: ""), isOn: $settings.indexVisibility.bottom)
                        Toggle(NSLocalizedString("show_left_labels", comment: ""), isOn: $settings.indexVisibility.left)
                        Toggle(NSLocalizedString("show_right_labels", comment: ""), isOn: $settings.indexVisibility.right)
                    }

                    Group {
                        ColorPicker(NSLocalizedString("top_color", comment: ""), selection: $settings.indexColors.top)
                        ColorPicker(NSLocalizedString("bottom_color", comment: ""), selection: $settings.indexColors.bottom)
                        ColorPicker(NSLocalizedString("left_color", comment: ""), selection: $settings.indexColors.left)
                        ColorPicker(NSLocalizedString("right_color", comment: ""), selection: $settings.indexColors.right)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Button(NSLocalizedString("make_labels_transparent", comment: "")) {
                            settings.indexColors = .transparent
                        }
                        .buttonStyle(.bordered)

                        Button(NSLocalizedString("reset_label_colors", comment: "")) {
                            settings.indexColors = IndexColors()
                        }
                        .buttonStyle(.bordered)
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
                    Text(NSLocalizedString("turn_infinity", comment: "∞")).tag(Int?.none)
                }
                .pickerStyle(.segmented)
                .disabled(!settings.isPremium)

                if !settings.isPremium {
                    Text(NSLocalizedString("turn_timer_free_hint", comment: "Free version uses a fixed 30s per turn."))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // MARK: Header/UX Options
            Section(header: Text(NSLocalizedString("header_options", comment: ""))) {
                Toggle(NSLocalizedString("show_selected_coordinates_button", comment: ""),
                       isOn: $settings.showSelectedCoordinatesButton)
            }

            // MARK: Premium Access
            Section(header: Text(NSLocalizedString("premium_access", comment: ""))) {
                if settings.isPremium {
                    Text("✅ Premium Unlocked")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Button {
                        activeSheet = .paywall
                    } label: {
                        Text("Unlock Premium")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    // Links
                    HStack {
                        Button("Privacy Policy") { activeSheet = .privacy }
                        Spacer()
                        Button("Terms of Use")   { activeSheet = .terms }
                    }
                    .font(.footnote)
                }
            }
        }
        .navigationTitle(NSLocalizedString("settings_title", comment: ""))

        // Single sheet handles all cases → prevents double opening
        .sheet(item: $activeSheet, onDismiss: { activeSheet = nil }) { sheet in
            switch sheet {
            case .paywall:
                NavigationStack {
                    PaywallView(settings: $settings)
                }
            case .privacy:
                SafariView(url: URL(string: "https://github.com/KuuuGR/Memul/wiki/POLICIES#privacy-policy-for-memul")!)
                    .ignoresSafeArea()
            case .terms:
                SafariView(url: URL(string: "https://github.com/KuuuGR/Memul/wiki/TERMS#terms-of-use-for-memul")!)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if !settings.isPremium { settings.turnTimeLimit = 30 }
            if !settings.isPremium && settings.difficulty != .easy {
                settings.difficulty = .easy
            }
        }
    }

    // MARK: Helpers

    private var boardRange: ClosedRange<Int> {
        if settings.isPremium {
            1...GameSettings.premiumMaxBoardSize
        } else {
            GameSettings.freeMinBoardSize...GameSettings.freeMaxBoardSize
        }
    }

    private var maxPlayers: Int {
        settings.isPremium ? GameSettings.premiumMaxPlayers : GameSettings.freeMaxPlayers
    }

    /// Binding helper to support nil (= ∞) in segmented picker.
    private func bindingForTurnLimit() -> Binding<Int?> {
        Binding<Int?>(
            get: { settings.turnTimeLimit },
            set: { newValue in
                if !settings.isPremium {
                    settings.turnTimeLimit = 30
                } else {
                    settings.turnTimeLimit = newValue // 30/60/120 or nil (∞)
                }
            }
        )
    }
}
