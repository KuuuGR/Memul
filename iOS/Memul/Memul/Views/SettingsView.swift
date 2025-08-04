//
//  SettingsView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 04/08/2025.
//


import SwiftUI

struct SettingsView: View {
    @Binding var settings: GameSettings
    @State private var isPremium = false

    var body: some View {
        Form {
            Section(header: Text("Board Size")) {
                Stepper(value: $settings.boardSize, in: 1...maxBoardSize) {
                    Text("Size: \(settings.boardSize) × \(settings.boardSize)")
                }
            }

            Section(header: Text("Players")) {
                ForEach(0..<settings.players.count, id: \.self) { index in
                    TextField("Player \(index + 1)", text: $settings.players[index].name)
                }

                if settings.players.count < maxPlayers {
                    Button("Add Player") {
                        let newColor: Color = .green // just rotate through options if needed
                        settings.players.append(Player(name: "Player \(settings.players.count + 1)", color: newColor))
                    }
                }

                if settings.players.count > 1 {
                    Button("Remove Last Player", role: .destructive) {
                        settings.players.removeLast()
                    }
                }
            }

            Section(header: Text("Premium Access")) {
                Toggle("Unlock Premium", isOn: $isPremium)
                    .onChange(of: isPremium) {
                        if !isPremium {
                            // Enforce free limitations
                            if settings.boardSize > GameSettings.freeMaxBoardSize {
                                settings.boardSize = GameSettings.freeMaxBoardSize
                            }
                            if settings.players.count > GameSettings.freeMaxPlayers {
                                settings.players = Array(settings.players.prefix(GameSettings.freeMaxPlayers))
                            }
                        }
                    }

                if !isPremium {
                    Text("Free version: max \(GameSettings.freeMaxBoardSize)×\(GameSettings.freeMaxBoardSize) board, \(GameSettings.freeMaxPlayers) players.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var maxBoardSize: Int {
        isPremium ? 12 : GameSettings.freeMaxBoardSize
    }

    private var maxPlayers: Int {
        isPremium ? 16 : GameSettings.freeMaxPlayers
    }
}
