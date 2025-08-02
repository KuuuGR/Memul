//
//  HUDView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct HUDView: View {
    let players: [Player]
    var currentPlayerIndex: Int?

    var body: some View {
        VStack {
            HStack {
                ForEach(players.indices, id: \.self) { index in
                    VStack {
                        Text(players[index].name)
                            .font(.caption)
                            .foregroundColor(players[index].color)

                        Text("\(players[index].score)")
                            .font(.headline)
                            .foregroundColor(index == currentPlayerIndex ? .yellow : .white)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.3))
                    )
                }
            }
            .padding()
        }
    }
}
