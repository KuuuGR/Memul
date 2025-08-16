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
    @State private var highlightedCell: Cell? = nil
    @State private var showResults = false
    @State private var scoreAnimation: (CGPoint, Color)? = nil
    @State private var showConfetti = false

    // Hide helper after the first confirmed submit
    @State private var hasConfirmedOnce = false

    private let cellSize: CGFloat = 40
    private let spacing: CGFloat = 2

    var body: some View {
        VStack(spacing: 12) {

            // MARK: Header
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
                .transition(.opacity.combined(with: .scale))
                .id(viewModel.currentPlayer.id)

                // Target chip (clear goal)
                HStack {
                    Label(
                        String(format: NSLocalizedString("gv_target", comment: "Target: %d"),
                               viewModel.currentTarget),
                        systemImage: "target"
                    )
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.primary.opacity(0.06)))
                    Spacer()
                }

                // Submit (primary). Disabled until a selection exists.
                HStack {
                    if let sel = viewModel.currentSelection {
                        Button {
                            submitSelectionConfirmed()
                        } label: {
                            Label(
                                String(format: NSLocalizedString("gv_submit_sel", comment: "Submit (%d, %d)"), sel.row, sel.col),
                                systemImage: "checkmark.circle.fill"
                            )
                            .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .accessibilityLabel(
                            Text(
                                String(format: NSLocalizedString("gv_submit_sel_ax", comment: "Submit selected coordinates %d, %d"),
                                       sel.row, sel.col)
                            )
                        )
                    } else {
                        Button {
                            // no-op (disabled)
                        } label: {
                            Label(NSLocalizedString("gv_submit", comment: "Submit"), systemImage: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(true)
                        .opacity(0.6)
                        .accessibilityHint(Text(NSLocalizedString("gv_submit_hint", comment: "Select a cell first")))
                    }
                    Spacer()
                }
            }
            .padding(.top, 12)
            .padding(.horizontal)

            // MARK: Scrollable Board (both directions)
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: spacing) {
                    // Top column numbers
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

                    // Rows with cells
                    ForEach(1...viewModel.settings.boardSize, id: \.self) { row in
                        HStack(spacing: spacing) {
                            // Left row number
                            Text("\(row)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.left)
                                .opacity(viewModel.settings.indexVisibility.left ? 1 : 0)

                            ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                                if let cell = viewModel.cells.first(where: { $0.row == row && $0.col == col }) {

                                    ZStack {
                                        // Base cell
                                        CellView(
                                            cell: cell,
                                            isHighlighted: isCellHighlighted(cell),
                                            isTarget: cell.value == viewModel.currentTarget,
                                            puzzlePiece: getPuzzlePiece(row: row, col: col),
                                            cellSize: cellSize
                                        )

                                        // Compact rounded highlight marker (¼ size) for selected row/col
                                        if isCellHighlighted(cell) {
                                            RoundedRectangle(cornerRadius: cellSize * 0.2, style: .continuous)
                                                .stroke(Color(.systemYellow), lineWidth: 2)
                                                .frame(width: cellSize / 2, height: cellSize / 2)
                                        }

                                        // 🎯 Target emoji at the tapped crossing
                                        if let sel = viewModel.currentSelection,
                                           sel.row == row && sel.col == col {
                                            Text("🎯")
                                                .font(.system(size: cellSize * 0.6))
                                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                                                .transition(.scale.combined(with: .opacity))
                                                .accessibilityLabel(
                                                    Text(
                                                        String(
                                                            format: NSLocalizedString("selected_coordinates", comment: "(%d, %d)"),
                                                            row, col
                                                        )
                                                    )
                                                )
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

                            // Right row number (auto-hide if board < 7)
                            Text("\(row)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.right)
                                .opacity(
                                    (viewModel.settings.indexVisibility.right && viewModel.settings.boardSize >= 7) ? 1 : 0
                                )
                        }
                    }

                    // Bottom column numbers (auto-hide if board < 7)
                    HStack(spacing: spacing) {
                        Text("").frame(width: cellSize, height: cellSize)
                        ForEach(1...viewModel.settings.boardSize, id: \.self) { col in
                            Text("\(col)")
                                .frame(width: cellSize, height: cellSize)
                                .font(.caption)
                                .foregroundColor(viewModel.settings.indexColors.bottom)
                                .opacity(
                                    (viewModel.settings.indexVisibility.bottom && viewModel.settings.boardSize >= 7) ? 1 : 0
                                )
                        }
                        Text("").frame(width: cellSize, height: cellSize)
                    }
                }
                .padding()
                .frame(
                    minWidth: CGFloat(viewModel.settings.boardSize + 2) * cellSize + spacing,
                    minHeight: CGFloat(viewModel.settings.boardSize + 2) * cellSize + spacing
                )
            }

            // Helper hint (shows after a selection until the first confirmed submit)
            if viewModel.currentSelection != nil && !hasConfirmedOnce {
                Text(NSLocalizedString("gv_tap_again", comment: "Tap again to confirm or press Submit"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                    .transition(.opacity)
            }

            // MARK: HUD + End Game
            VStack(spacing: 10) {
                Text(NSLocalizedString("total_points", comment: "Section title for player scores"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FlexibleScoreView(players: viewModel.settings.players, currentPlayerId: viewModel.currentPlayer.id)

                Button(NSLocalizedString("end_game", comment: "End Game")) {
                    showResults = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.bottom, 12)
            .background(Color(UIColor.systemBackground))
        }
        .overlay(
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
        )
        .fullScreenCover(isPresented: $showResults, onDismiss: {
            viewModel.resumeTurnTimerIfNeeded()
        }) {
            ResultsView(viewModel: viewModel)
                .onAppear { viewModel.pauseTurnTimer() }
        }
        .onChange(of: viewModel.showPuzzleOverlay) { _, isShown in
            if isShown { viewModel.pauseTurnTimer() }
            else { viewModel.resumeTurnTimerIfNeeded() }
        }
        .animation(.easeInOut, value: viewModel.currentPlayer.id)
    }

    // MARK: - Tap handling

    private func handleTap(row: Int, col: Int, cell: Cell) {
        if let current = viewModel.currentSelection, current.row == row && current.col == col {
            // Second tap on same cell -> submit
            submitSelectionConfirmed()
        } else {
            // First tap -> select + haptic + pop-in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.firstTap(row: row, col: col)
            }
            UIAccessibility.post(notification: .announcement, argument:
                String(format: NSLocalizedString("gv_selected_ax", comment: "Selected row %d, column %d"), row, col)
            )
        }
    }

    private func submitSelectionConfirmed() {
        guard let sel = viewModel.currentSelection,
              let cell = viewModel.cells.first(where: { $0.row == sel.row && $0.col == sel.col })
        else { return }

        let wasCorrect = viewModel.isCorrectSelection(cell)

        // Haptics
        if wasCorrect {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.submitCurrentSelection()
            hasConfirmedOnce = true
        }

        if wasCorrect { playCorrectSound() } else { playWrongSound() }
    }

    // MARK: - Helpers

    private func isCellHighlighted(_ cell: Cell) -> Bool {
        if let sel = viewModel.currentSelection {
            return sel.row == cell.row || sel.col == cell.col
        }
        return false
    }

    private func playCorrectSound() { AudioServicesPlaySystemSound(1057) }
    private func playWrongSound() { AudioServicesPlaySystemSound(1053) }
    
    private func getPuzzlePiece(row: Int, col: Int) -> Image? {
        let r = row - 1
        let c = col - 1
        if viewModel.puzzlePieces.indices.contains(r),
           viewModel.puzzlePieces[r].indices.contains(c) {
            return viewModel.puzzlePieces[r][c]
        }
        return nil
    }

    // Timer label inside the chip (localized suffix)
    private func timerChipText() -> String {
        if let remaining = viewModel.timeRemaining {
            return String(
                format: NSLocalizedString("turn_seconds_suffix", comment: " (%ds)"),
                remaining
            )
        } else {
            return String(
                format: NSLocalizedString("turn_infinity_suffix", comment: " (%@)"),
                NSLocalizedString("turn_infinity", comment: "∞")
            )
        }
    }

    // (Optional) You can still keep the coordinates button if you want it elsewhere:
    private var coordinatesButton: some View {
        let coords = viewModel.currentSelection
        let rowText = coords?.row != nil ? "\(coords!.row)" : " "
        let colText = coords?.col != nil ? "\(coords!.col)" : " "

        return Button {
            viewModel.submitCurrentSelection()
        } label: {
            HStack(spacing: 8) {
                Text("(").foregroundColor(.secondary)
                Text(rowText).fontWeight(.bold).foregroundColor(viewModel.settings.indexColors.left)
                Text(",").foregroundColor(.secondary)
                Text(colText).fontWeight(.bold).foregroundColor(viewModel.settings.indexColors.top)
                Text(")").foregroundColor(.secondary)
            }
            .font(.title3)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(
                String(
                    format: NSLocalizedString("selected_coordinates", comment: "(%d, %d)"),
                    Int(rowText) ?? 0,
                    Int(colText) ?? 0
                )
            )
        )
    }
}
