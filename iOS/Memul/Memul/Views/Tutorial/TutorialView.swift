//
//  TutorialView.swift
//  Memul
//
//  Created by KuuuGR on 08/08/2025.
//

import SwiftUI

struct TutorialView: View {
    // MARK: - Config
    private let boardSize = 4
    private let cellSize: CGFloat = 42
    private let spacing: CGFloat = 4

    // MARK: - Phases
    private enum Phase { case rows, cols, intersect, framed, practice }
    @State private var phase: Phase = .rows

    // MARK: - Targets
    @State private var targetRow = 1
    @State private var targetCol = 1

    // MARK: - Animation progress (0..1)
    @State private var rowProgress: CGFloat = 0
    @State private var colProgress: CGFloat = 0

    // MARK: - Playback state
    @State private var isAnimating = false
    @State private var lastRowPlayed: Int? = nil     // also used as “picked row” in Intersect
    @State private var lastColPlayed: Int? = nil     // also used as “picked col” in Intersect
    @State private var lastPlayedWasRow = true

    // MARK: - Practice state
    @State private var userSelection: (row: Int, col: Int)?
    @State private var wasCorrect = false
    @State private var practiceWrongCell: (row: Int, col: Int)?
    @State private var hasSolvedOnce = false         // gates Quit button
    @State private var showQuitConfirm = false

    // Cumulative score
    @State private var rightCount = 0
    @State private var wrongCount = 0

    // MARK: - Framed step: in-cell feedback overlays
    @State private var framedCorrectCell: (row: Int, col: Int)?
    @State private var framedWrongCell: (row: Int, col: Int)?

    // MARK: - Timing
    private let sweepDuration: Double = 1.1

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            header

            // Board (lasers, header highlights, in-cell overlays)
            TutorialBoardView(
                boardSize: boardSize,
                cellSize: cellSize,
                spacing: spacing,
                targetRow: targetRow,
                targetCol: targetCol,

                // lasers (in Intersect, only show after user picked the axis)
                showRowLaser: (phase == .rows)
                              || (phase == .intersect && lastRowPlayed != nil),
                showColLaser: (phase == .cols)
                              || (phase == .intersect && lastColPlayed != nil),
                rowProgress: rowProgress,
                colProgress: colProgress,

                // header highlights
                // NOTE: practice has no hints now (removed from these conditions)
                highlightTopHeader: (phase == .cols)
                                    || (phase == .intersect && lastColPlayed != nil)
                                    || (phase == .framed),
                highlightLeftHeader: (phase == .rows)
                                     || (phase == .intersect && lastRowPlayed != nil)
                                     || (phase == .framed),

                // no row/col cell frames
                highlightRowCells: false,
                highlightColCells: false,

                // stage-gated overlays/glows
                showFramedOverlays: phase == .framed,
                showPracticeOverlays: phase == .practice,
                enableIntersectionGlow: phase == .intersect,                 // lasers-cross glow
                practiceShowGlow: phase == .practice && wasCorrect,          // product glow + green outline on correct

                // overlay data
                framedCorrectCell: framedCorrectCell,                        // ✅ in framed
                framedWrongCell: framedWrongCell,                            // ❌ in framed
                practiceWrongCell: practiceWrongCell,                        // ❌ 0.5s in practice

                // Taps
                onTapTopHeader: { c in
                    guard !isAnimating else { return }
                    if phase == .cols || phase == .intersect { playCol(c) }
                },
                onTapLeftHeader: { r in
                    guard !isAnimating else { return }
                    if phase == .rows || phase == .intersect { playRow(r) }
                },
                onTapCell: { r, c in
                    switch phase {
                    case .practice:
                        // Wrong -> ❌ for 0.5s (+1 wrong); Correct -> glow+outline (+1 right once)
                        if r == targetRow && c == targetCol {
                            if !wasCorrect { rightCount += 1 }
                            practiceWrongCell = nil
                            userSelection = (r, c)
                            wasCorrect = true
                            hasSolvedOnce = true
                        } else {
                            guard !wasCorrect else { return } // ignore wrong after success
                            wrongCount += 1
                            wasCorrect = false
                            userSelection = (r, c)
                            practiceWrongCell = (r, c)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let wrong = practiceWrongCell, wrong.row == r && wrong.col == c {
                                    practiceWrongCell = nil
                                }
                            }
                        }

                    case .framed:
                        // ✅ on correct; ❌ for 1s on wrong; no auto-advance.
                        if r == targetRow && c == targetCol {
                            framedWrongCell = nil
                            framedCorrectCell = (r, c)
                        } else {
                            guard framedCorrectCell == nil else { return }
                            framedCorrectCell = nil
                            framedWrongCell = (r, c)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if let wrong = framedWrongCell, wrong.row == r && wrong.col == c {
                                    framedWrongCell = nil
                                }
                            }
                        }

                    default:
                        break
                    }
                }
            )
            .frame(
                width: TutorialBoardView.pixelWidth(boardSize: boardSize, cellSize: cellSize, spacing: spacing),
                height: TutorialBoardView.pixelHeight(boardSize: boardSize, cellSize: cellSize, spacing: spacing)
            )

            // Annotation / inline messages (Rows / Cols / Intersect / Framed / Practice)
            annotation

            // Trigger buttons (keep buttons + header taps)
            if phase == .rows {
                rowButtons
            } else if phase == .cols {
                columnButtons
            } else if phase == .intersect {
                VStack(spacing: 6) {
                    rowButtons
                    columnButtons
                }
            }

            // Controls
            if phase == .practice {
                practiceControlBar
            } else {
                standardControlBar
            }
        }
        .padding()
        .navigationTitle(NSLocalizedString("tutorial_title", comment: "Tutorial"))
        .alert(NSLocalizedString("tutorial_quit_title", comment: "Quit confirm title"),
               isPresented: $showQuitConfirm) {
            Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) { }
            Button(NSLocalizedString("quit", comment: "Quit"), role: .destructive) { dismiss() }
        } message: {
            Text(NSLocalizedString("tutorial_quit_message", comment: "Quit message"))
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 6) {
            switch phase {
            case .rows:
                Text(NSLocalizedString("tutorial_rows_title", comment: "Rows"))
                    .font(.title3).bold()
                Text(NSLocalizedString("tutorial_rows_sub", comment: "Rows subtitle"))
                Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row label"), targetRow))
                    .foregroundStyle(.red)
                    .font(.subheadline)

            case .cols:
                Text(NSLocalizedString("tutorial_cols_title", comment: "Columns"))
                    .font(.title3).bold()
                Text(NSLocalizedString("tutorial_cols_sub", comment: "Columns subtitle"))
                Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Column label"), targetCol))
                    .foregroundStyle(.blue)
                    .font(.subheadline)

            case .intersect:
                Text(NSLocalizedString("tutorial_intersect_title", comment: "Intersection"))
                    .font(.title3).bold()
                Text(NSLocalizedString("tutorial_intersect_sub", comment: "Intersection subtitle"))
                HStack(spacing: 16) {
                    Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row"), targetRow)).foregroundStyle(.red)
                    Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Col"), targetCol)).foregroundStyle(.blue)
                }
                .font(.subheadline)

            case .framed:
                Text(NSLocalizedString("tutorial_framed_title", comment: "Intersection — Part 2"))
                    .font(.title3).bold()
                Text(NSLocalizedString("tutorial_framed_sub", comment: "Tap where a row meets a column."))
                HStack(spacing: 16) {
                    Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row"), targetRow)).foregroundStyle(.red)
                    Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Col"), targetCol)).foregroundStyle(.blue)
                }
                .font(.subheadline)

            case .practice:
                Text(NSLocalizedString("tutorial_practice_title", comment: "Try it!"))
                    .font(.title3).bold()
                Text(NSLocalizedString("tutorial_practice_hint", comment: "Find the crossing cell..."))
                HStack(spacing: 16) {
                    Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row"), targetRow)).foregroundStyle(.red)
                    Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Col"), targetCol)).foregroundStyle(.blue)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Annotation / inline messages
    private var annotation: some View {
        switch phase {
        case .rows:
            return AnyView(infoCard(
                title: NSLocalizedString("tutorial_rows_card_title", comment: "Rows card title"),
                body: NSLocalizedString("tutorial_rows_card_body", comment: "Rows card body")
            ))
        case .cols:
            return AnyView(infoCard(
                title: NSLocalizedString("tutorial_cols_card_title", comment: "Columns card title"),
                body: NSLocalizedString("tutorial_cols_card_body", comment: "Columns card body")
            ))
        case .intersect:
            return AnyView(infoCard(
                title: NSLocalizedString("tutorial_intersect_card_title", comment: "Intersect card title"),
                body: NSLocalizedString("tutorial_intersect_card_body", comment: "Intersect card body")
            ))
        case .framed:
            return AnyView(infoCard(
                title: NSLocalizedString("tutorial_framed_card_title", comment: "Framed card title"),
                body: NSLocalizedString("tutorial_framed_card_body", comment: "Framed card body")
            ))
        case .practice:
            return AnyView(
                VStack(spacing: 8) {
                    Text(NSLocalizedString("tutorial_practice_callout", comment: "Practice headline"))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack(spacing: 12) {
                        scoreCard.frame(maxWidth: .infinity)
                        questCard.frame(maxWidth: .infinity)
                    }
                }
            )
        }
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("qp_score_title", comment: "Score")).font(.headline)
            HStack {
                Text(String(format: NSLocalizedString("tutorial_score_right", comment: "Right count"), rightCount))
                    .foregroundStyle(.green)
                Text(String(format: NSLocalizedString("tutorial_score_wrong", comment: "Wrong count"), wrongCount))
                    .foregroundStyle(.red)
            }
            .font(.subheadline)
        }
        .padding(12)
        .frame(minHeight: 64)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private var questCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("tutorial_quest_title", comment: "Quest")).font(.headline)
            if wasCorrect {
                Text(String(format: NSLocalizedString("tutorial_equation", comment: "a × b = c"),
                            targetRow, targetCol, targetRow * targetCol))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(String(format: NSLocalizedString("tutorial_quest_tap_pair", comment: "Tap (r ; c)"),
                            targetRow, targetCol))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(minHeight: 64)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(body).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Row / Column trigger buttons (plus header taps)
    private var rowButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...boardSize, id: \.self) { r in
                Button(String(format: NSLocalizedString("tutorial_row_button", comment: "Row n"), r)) { playRow(r) }
                    .buttonStyle(.bordered)
                    .tint(.red)               // rows are red
                    .disabled(isAnimating)
            }
        }
    }

    private var columnButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...boardSize, id: \.self) { c in
                Button(String(format: NSLocalizedString("tutorial_col_button", comment: "Col. n"), c)) { playCol(c) }
                    .buttonStyle(.bordered)
                    .tint(.blue)              // columns are blue
                    .disabled(isAnimating)
            }
        }
    }

    // MARK: - Controls
    private var standardControlBar: some View {
        HStack {
            Button(NSLocalizedString("back", comment: "Back")) { goBack() }
                .buttonStyle(.bordered)
                .disabled(isAnimating || phase == .rows)

            Spacer()

            if phase == .rows || phase == .cols || phase == .intersect {
                Button(NSLocalizedString("repeat", comment: "Repeat")) { repeatCurrent() }
                    .buttonStyle(.bordered)
                    .disabled(isAnimating || isRepeatDisabled)
                Spacer()
            }

            Button(NSLocalizedString("next", comment: "Next")) { goNext() }
                .buttonStyle(.borderedProminent)
                .disabled(isAnimating || isNextDisabled)
        }
        .padding(.top, 2)
    }

    private var practiceControlBar: some View {
        HStack {
            Button(NSLocalizedString("back", comment: "Back")) {
                // Reset practice state when going back (keep score)
                practiceWrongCell = nil
                userSelection = nil
                wasCorrect = false
                phase = .framed
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(NSLocalizedString("tutorial_next_quest", comment: "Next Quest")) {
                newPracticeRound() // keep cumulative score
            }
            .buttonStyle(.bordered)
            .tint(.yellow)

            Spacer()

            Button(NSLocalizedString("quit", comment: "Quit")) {
                showQuitConfirm = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasSolvedOnce) // enabled only after first correct solution
        }
        .padding(.top, 2)
    }

    private var isRepeatDisabled: Bool {
        switch phase {
        case .rows:      return lastRowPlayed == nil
        case .cols:      return lastColPlayed == nil
        case .intersect: return (lastRowPlayed == nil && lastColPlayed == nil)
        default:         return true
        }
    }

    private var isNextDisabled: Bool {
        switch phase {
        case .rows:      return lastRowPlayed == nil
        case .cols:      return lastColPlayed == nil
        case .intersect: return (lastRowPlayed == nil || lastColPlayed == nil) // must pick both before Next
        case .framed:    return framedCorrectCell == nil
        case .practice:  return true // practice uses Back/Next Quest/Quit, no Next
        }
    }

    // MARK: - Navigation
    private func goBack() {
        switch phase {
        case .cols:
            phase = .rows
        case .intersect:
            phase = .cols
        case .framed:
            framedCorrectCell = nil
            framedWrongCell = nil
            phase = .intersect
        case .practice:
            // handled by practiceControlBar Back
            break
        case .rows:
            break
        }
    }

    private func goNext() {
        switch phase {
        case .rows:
            phase = .cols

        case .cols:
            // Enter Intersect clean: no lasers until user taps.
            lastRowPlayed = nil
            lastColPlayed = nil
            rowProgress = 0
            colProgress = 0
            phase = .intersect

        case .intersect:
            // entering framed fresh
            framedCorrectCell = nil
            framedWrongCell = nil
            phase = .framed

        case .framed:
            // clear framed badges on exit, then move to practice
            framedCorrectCell = nil
            framedWrongCell = nil
            practiceWrongCell = nil
            userSelection = nil
            wasCorrect = false
            phase = .practice

        case .practice:
            break
        }
    }

    private func repeatCurrent() {
        switch phase {
        case .rows:
            if let r = lastRowPlayed { playRow(r) }
        case .cols:
            if let c = lastColPlayed { playCol(c) }
        case .intersect:
            if lastPlayedWasRow, let r = lastRowPlayed { playRow(r) }
            else if let c = lastColPlayed { playCol(c) }
        default:
            break
        }
    }

    // MARK: - Playback
    private func playRow(_ r: Int) {
        targetRow = r
        lastRowPlayed = r
        lastPlayedWasRow = true
        rowProgress = 0
        isAnimating = true
        withAnimation(.easeInOut(duration: sweepDuration)) { rowProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + 0.02) {
            isAnimating = false
        }
    }

    private func playCol(_ c: Int) {
        targetCol = c
        lastColPlayed = c
        lastPlayedWasRow = false
        colProgress = 0
        isAnimating = true
        withAnimation(.easeInOut(duration: sweepDuration)) { colProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + 0.02) {
            isAnimating = false
        }
    }

    // MARK: - Practice
    private func newPracticeRound() {
        practiceWrongCell = nil
        userSelection = nil
        wasCorrect = false
        // keep score counters
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
    }
}
