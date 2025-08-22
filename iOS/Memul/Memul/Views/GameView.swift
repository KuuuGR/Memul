//
//  GameView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI
import AVFoundation

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel

    // MARK: - State
    @State private var showResults = false
    @State private var hasConfirmedOnce = false

    // Visual spacing between tiles
    private let spacing: CGFloat = 2

    var body: some View {
        VStack(spacing: 12) {
            headerSection
            submitSection
            boardSection        // adaptive board
            hudSection
        }
        .overlay(puzzleOverlay)
        .fullScreenCover(isPresented: $showResults, onDismiss: { viewModel.resumeTurnTimerIfNeeded() }) {
            ResultsView(viewModel: viewModel)
                .onAppear { viewModel.pauseTurnTimer() }
        }
        .onChange(of: viewModel.showPuzzleOverlay) { _, isShown in
            if isShown { viewModel.pauseTurnTimer() } else { viewModel.resumeTurnTimerIfNeeded() }
        }
        .animation(.easeInOut, value: viewModel.currentPlayer.id)
    }
}

// MARK: - UI Sections
private extension GameView {

    var headerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Label(
                    String(format: NSLocalizedString("turn_title", comment: "%@'s turn"),
                           viewModel.currentPlayer.name),
                    systemImage: "person.fill"
                )
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundStyle(viewModel.currentPlayer.color)

                Text(timerChipText())
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .id(viewModel.currentPlayer.id)

            HStack {
                Label(
                    String(format: NSLocalizedString("gv_target", comment: "Target: %d"),
                           viewModel.currentTarget),
                    systemImage: "target"
                )
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.06)))
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    var submitSection: some View {
        VStack(spacing: 2) {
            HStack {
                if let sel = viewModel.currentSelection {
                    Button { submitSelectionConfirmed() } label: {
                        Label {
                            HStack(spacing: 4) {
                                Text(NSLocalizedString("gv_submit_prefix", comment: "Submit ("))
                                    .foregroundColor(.secondary)
                                capsuleText("\(sel.row)", color: .red)
                                Text(NSLocalizedString("gv_submit_separator", comment: ","))
                                    .foregroundColor(.secondary)
                                capsuleText("\(sel.col)", color: .blue)
                                Text(NSLocalizedString("gv_submit_suffix", comment: ")"))
                                    .foregroundColor(.secondary)
                            }
                            .font(.body.weight(.semibold))
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .accessibilityLabel(
                        Text(String(format: NSLocalizedString("gv_submit_sel_ax", comment: "Submit %d, %d"),
                                    sel.row, sel.col))
                    )
                } else {
                    Button {} label: {
                        Label(NSLocalizedString("gv_submit", comment: "Submit"),
                              systemImage: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(true)
                    .opacity(0.6)
                }
                Spacer()
            }
            .padding(.horizontal)

            if viewModel.currentSelection != nil && !hasConfirmedOnce {
                Text(NSLocalizedString("gv_tap_again", comment: "Tap again to confirm or press Submit"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Adaptive board
    var boardSection: some View {
        GeometryReader { geo in
            let availW: CGFloat = geo.size.width  - 16
            let availH: CGFloat = geo.size.height - 16

            let sizeN: Int = viewModel.settings.boardSize
            let n: CGFloat = CGFloat(sizeN)

            // visible index headers
            let showTop    = viewModel.settings.indexVisibility.top
            let showBottom = viewModel.settings.indexVisibility.bottom && sizeN >= 7
            let showLeft   = viewModel.settings.indexVisibility.left
            let showRight  = viewModel.settings.indexVisibility.right && sizeN >= 7

            let headerCols: CGFloat = CGFloat((showLeft ? 1 : 0) + (showRight ? 1 : 0))
            let headerRows: CGFloat = CGFloat((showTop ? 1 : 0) + (showBottom ? 1 : 0))

            // counts including headers
            let totalCols: CGFloat = n + headerCols
            let totalRows: CGFloat = n + headerRows

            // pixels taken by gaps
            let gapW: CGFloat = spacing * (totalCols - 1)
            let gapH: CGFloat = spacing * (totalRows - 1)

            // max tile size that fits both axes
            let tileW: CGFloat = (availW  - gapW) / totalCols
            let tileH: CGFloat = (availH - gapH) / totalRows

            let minTile: CGFloat = 32  // minimum square side in points
            let tileSize: CGFloat = max(minTile, floor(min(tileW, tileH)))

            // Scalable fonts for index labels
            let labelPt = max(10, tileSize * 0.28)
            let labelFont = Font.system(size: labelPt, weight: .regular, design: .rounded)

            // final board pixels
            let boardW: CGFloat = tileSize * totalCols + gapW
            let boardH: CGFloat = tileSize * totalRows + gapH

            // arrays for ForEach
            let rows = Array(1...sizeN)
            let cols = Array(1...sizeN)

            ScrollView([.vertical, .horizontal], showsIndicators: false) {
                VStack(spacing: spacing) {

                    // Top numbers
                    if showTop {
                        HStack(spacing: spacing) {
                            if showLeft { spacerCell(tileSize) }
                            ForEach(cols, id: \.self) { col in
                                Text("\(col)")
                                    .frame(width: tileSize, height: tileSize)
                                    .font(labelFont)
                                    .foregroundColor(viewModel.settings.indexColors.top)
                            }
                            if showRight { spacerCell(tileSize) }
                        }
                    }

                    // Grid rows
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            if showLeft {
                                Text("\(row)")
                                    .frame(width: tileSize, height: tileSize)
                                    .font(labelFont)
                                    .foregroundColor(viewModel.settings.indexColors.left)
                            }

                            ForEach(cols, id: \.self) { col in
                                if let cell = viewModel.cells.first(where: { $0.row == row && $0.col == col }) {
                                    boardCell(cell, row: row, col: col, cellSize: tileSize)
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: tileSize, height: tileSize)
                                }
                            }

                            if showRight {
                                Text("\(row)")
                                    .frame(width: tileSize, height: tileSize)
                                    .font(labelFont)
                                    .foregroundColor(viewModel.settings.indexColors.right)
                            }
                        }
                    }

                    // Bottom numbers
                    if showBottom {
                        HStack(spacing: spacing) {
                            if showLeft { spacerCell(tileSize) }
                            ForEach(cols, id: \.self) { col in
                                Text("\(col)")
                                    .frame(width: tileSize, height: tileSize)
                                    .font(labelFont)
                                    .foregroundColor(viewModel.settings.indexColors.bottom)
                            }
                            if showRight { spacerCell(tileSize) }
                        }
                    }
                }
                .frame(width: boardW, height: boardH)
                .padding(.horizontal, max(0, (availW  - boardW) / 2))
                .padding(.vertical,   max(0, (availH - boardH) / 2))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var hudSection: some View {
        VStack(spacing: 10) {
            Text(NSLocalizedString("total_points", comment: "Section title for scores"))
                .font(.caption)
                .foregroundStyle(.secondary)

            FlexibleScoreView(players: viewModel.settings.players,
                              currentPlayerId: viewModel.currentPlayer.id)

            Button(NSLocalizedString("end_game", comment: "End Game")) {
                showResults = true
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(.bottom, 12)
        .background(Color(UIColor.systemBackground))
    }

    var puzzleOverlay: some View {
        Group {
            if viewModel.showPuzzleOverlay, let image = viewModel.puzzleImageName {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { viewModel.dismissPuzzleOverlay() }

                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.opacity)
                    .onTapGesture { viewModel.dismissPuzzleOverlay() }
                    .accessibilityLabel(Text(NSLocalizedString("tap_to_close", comment: "Tap to close")))
            }
        }
    }
}

// MARK: - Board helpers
private extension GameView {

    func spacerCell(_ side: CGFloat) -> some View {
        Rectangle().fill(Color.clear).frame(width: side, height: side)
    }

    func boardCell(_ cell: Cell, row: Int, col: Int, cellSize: CGFloat) -> some View {
        ZStack {
            CellView(
                cell: cell,
                isHighlighted: isCellHighlighted(cell),
                isTarget: cell.value == viewModel.currentTarget,
                puzzlePiece: getPuzzlePiece(row: row, col: col),
                cellSize: cellSize
            )

            if isCellHighlighted(cell) {
                let corner = cellSize * 0.2
                RoundedRectangle(cornerRadius: corner)
                    .stroke(Color(.systemYellow), lineWidth: 2)
                    .frame(width: cellSize / 5, height: cellSize / 5)
            }

            if let sel = viewModel.currentSelection,
               sel.row == row && sel.col == col {
                Text("🎯")
                    .font(.system(size: cellSize * 0.6))
                    .shadow(color: .black.opacity(0.25), radius: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !cell.isRevealed else { return }
            handleTap(row: row, col: col, cell: cell)
        }
    }
}

// MARK: - Actions & Helpers
private extension GameView {
    func handleTap(row: Int, col: Int, cell: Cell) {
        if let current = viewModel.currentSelection,
           current.row == row && current.col == col {
            submitSelectionConfirmed()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.firstTap(row: row, col: col)
            }
        }
    }

    func submitSelectionConfirmed() {
        guard let sel = viewModel.currentSelection,
              let cell = viewModel.cells.first(where: { $0.row == sel.row && $0.col == sel.col })
        else { return }

        let wasCorrect = viewModel.isCorrectSelection(cell)
        UINotificationFeedbackGenerator().notificationOccurred(wasCorrect ? .success : .error)

        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.submitCurrentSelection()
            hasConfirmedOnce = true
        }
    }

    func isCellHighlighted(_ cell: Cell) -> Bool {
        if let sel = viewModel.currentSelection {
            return sel.row == cell.row || sel.col == cell.col
        }
        return false
    }

    func getPuzzlePiece(row: Int, col: Int) -> Image? {
        let r = row - 1
        let c = col - 1
        guard viewModel.puzzlePieces.indices.contains(r) else { return nil }
        guard viewModel.puzzlePieces[r].indices.contains(c) else { return nil }
        return viewModel.puzzlePieces[r][c]
    }

    func timerChipText() -> String {
        if let remaining = viewModel.timeRemaining {
            return String(format: NSLocalizedString("turn_seconds_suffix", comment: " (%ds)"), remaining)
        } else {
            let inf = NSLocalizedString("turn_infinity", comment: "∞")
            return String(format: NSLocalizedString("turn_infinity_suffix", comment: " (%@)"), inf)
        }
    }

    func capsuleText(_ text: String, color: Color) -> some View {
        Text(text)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white))
            .foregroundColor(color)
    }
}
