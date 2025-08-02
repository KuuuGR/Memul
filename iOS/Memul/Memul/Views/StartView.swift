//
//  StartView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct StartView: View {
    @State private var navigateToGame = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Memul")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Fun way to learn multiplication tables!")
                    .foregroundColor(.gray)
                
                Button(action: {
                    navigateToGame = true
                }) {
                    Text("Start Game")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                NavigationLink("", isActive: $navigateToGame) {
                    GameView(viewModel: previewGameViewModel)
                }
            }
        }
    }
}

// Preview ViewModel for testing
private var previewGameViewModel: GameViewModel {
    let players = [
        Player(name: "Alice", color: .red),
        Player(name: "Bob", color: .blue)
    ]
    let settings = GameSettings(boardSize: 5, players: players)
    return GameViewModel(settings: settings)
}
