import SwiftUI

struct FlexibleScoreView: View {
    let players: [Player]
    let currentPlayerId: UUID

    var body: some View {
        // Up to 4 columns; wraps automatically if more players
        let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 8, alignment: .leading), count: 4)

        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(players) { player in
                Text("\(player.name): \(player.score)")
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(player.color.opacity(player.id == currentPlayerId ? 0.4 : 0.2))
                    .cornerRadius(8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal)
    }
}
