//
//  ResultsView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct ResultsView: View {
    let players: [Player]
    
    var sortedPlayers: [Player] {
        players.sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Results")
                .font(.largeTitle)
                .bold()
            
            ForEach(sortedPlayers.prefix(3), id: \.id) { player in
                Text("\(player.name) - \(player.score) points")
                    .font(.title2)
            }
            
            Button("Play Again") {
                // TODO: Restart game
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
