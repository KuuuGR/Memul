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
    @State private var hasConfirmedOnce = false   // hides helper after first submit

    private let cellSize: CGFloat = 40
    private let spacing: CGFloat = 2

    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {

            headerSection
            submitSection
            boardSection
            hudSection
        }
        .overlay(puzzleOverlay)
        .fullScreenCover(isPresented: $showResults, onDismiss: { viewModel.resumeTurnTimerIfNeeded() }) {
            ResultsView(viewModel: viewModel)
                .onAppear { viewModel.pauseTurnTimer() }
        }
        .onChange(of: viewModel.showPuzzleOverlay) { _, isShown in
            if isShown { viewModel.pauseTurnTimer() }
            else { viewModel.resumeTurnTimerIfNeeded() }
        }
        .animation(.easeInOut, value: viewModel.currentPlayer.id)
    }
}

// MARK: - UI Sections
private extension GameView {

    /// Top player info and target
    var headerSection: some View {
        VStack(spacing: 10) {
            // Player + timer chips
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

            // Target chip
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

    /// Submit button row + helper text
    var submitSection: some View {
        VStack(spacing: 2) {
            HStack {
                if let sel = viewModel.currentSelection {
                    // When a selection exists, show either detailed (with coordinates) or plain submit
                    Button { submitSelectionConfirmed() } label: {
                        if viewModel.settings.showSelectedCoordinatesButton {
                            // Detailed label with coordinates capsules
                            Label {
                                HStack(spacing: 4) {
                                    Text(NSLocalizedString("gv_submit_prefix", comment: "Submit prefix"))
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
                        } else {
                            // Plain submit (no coordinates)
                            Label(NSLocalizedString("gv_submit", comment: "Submit"),
                                  systemImage: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .accessibilityLabel(
                        Text(
                            viewModel.settings.showSelectedCoordinatesButton
                            ? String(format: NSLocalizedString("gv_submit_sel_ax", comment: "Submit %d, %d"), sel.row, sel.col)
                            : NSLocalizedString("gv_submit", comment: "Submit")
                        )
                    )
                } else {
                    // No selection yet → disabled submit
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

    /// Main board with scroll
    var boardSection: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: spacing) {
                topColumns

                ForEach(1...viewModel.settings.boardSize, id: \.self) { row in
                    HStack(spacing: spacing) {
                        leftRow(row)

                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            if let cell = viewModel.cells.first(where: { $0.row == row && $0.col == col }) {
                                boardCell(cell, row: row, col: col)
                            }
                        }

                        rightRow(row)
                    }
                }

                bottomColumns
            }
            .padding()
            .frame(
                minWidth: CGFloat(viewModel.settings.boardSize + 2) * cellSize + spacing,
                minHeight: CGFloat(viewModel.settings.boardSize + 2) * cellSize + spacing
            )
        }
    }

    /// Scores + End Game
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

    /// Overlay with puzzle image
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
    var topColumns: some View {
        HStack(spacing: spacing) {
            Text("").frame(width: cellSize, height: cellSize)
            ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                Text("\(col)")
                    .frame(width: cellSize, height: cellSize)
                    .font(.caption)
                    .foregroundColor(viewModel.settings.indexColors.top)
                    .opacity(viewModel.settings.indexVisibility.top ? 1 : 0)
            }
            Text("").frame(width: cellSize, height: cellSize)
        }
    }

    func leftRow(_ row: Int) -> some View {
        Text("\(row)")
            .frame(width: cellSize, height: cellSize)
            .font(.caption)
            .foregroundColor(viewModel.settings.indexColors.left)
            .opacity(viewModel.settings.indexVisibility.left ? 1 : 0)
    }

    func rightRow(_ row: Int) -> some View {
        Text("\(row)")
            .frame(width: cellSize, height: cellSize)
            .font(.caption)
            .foregroundColor(viewModel.settings.indexColors.right)
            .opacity((viewModel.settings.indexVisibility.right && viewModel.settings.boardSize >= 7) ? 1 : 0)
    }

    var bottomColumns: some View {
        HStack(spacing: spacing) {
            Text("").frame(width: cellSize, height: cellSize)
            ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                Text("\(col)")
                    .frame(width: cellSize, height: cellSize)
                    .font(.caption)
                    .foregroundColor(viewModel.settings.indexColors.bottom)
                    .opacity((viewModel.settings.indexVisibility.bottom && viewModel.settings.boardSize >= 7) ? 1 : 0)
            }
            Text("").frame(width: cellSize, height: cellSize)
        }
    }

    func boardCell(_ cell: Cell, row: Int, col: Int) -> some View {
        ZStack {
            CellView(
                cell: cell,
                isHighlighted: isCellHighlighted(cell),
                isTarget: cell.value == viewModel.currentTarget,
                puzzlePiece: getPuzzlePiece(row: row, col: col),
                cellSize: cellSize
            )

            if isCellHighlighted(cell) {
                RoundedRectangle(cornerRadius: cellSize * 0.2)
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
        let r = row - 1, c = col - 1
        if viewModel.puzzlePieces.indices.contains(r),
           viewModel.puzzlePieces[r].indices.contains(c) {
            return viewModel.puzzlePieces[r][c]
        }
        return nil
    }

    func timerChipText() -> String {
        if let remaining = viewModel.timeRemaining {
            return String(format: NSLocalizedString("turn_seconds_suffix", comment: " (%ds)"), remaining)
        } else {
            return String(format: NSLocalizedString("turn_infinity_suffix", comment: " (%@)"),
                          NSLocalizedString("turn_infinity", comment: "∞"))
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
