//
//  TutorialView.swift
//  Memul
//
//  Created by KuuuGR on 08/08/2025.
//

import SwiftUI

struct TutorialView: View {
    // MARK: Config
    private let boardSize = 4
    private let cellSize: CGFloat = 42
    private let spacing: CGFloat = 4

    // MARK: Phases
    private enum Phase {
        case rows, cols, intersect, framed, practice, feedback
    }

    @State private var phase: Phase = .rows

    // Selection
    @State private var targetRow = 1
    @State private var targetCol = 1

    // Animation progress (0...1)
    @State private var rowProgress: CGFloat = 0
    @State private var colProgress: CGFloat = 0

    // Playback state
    @State private var isAnimating = false
    @State private var lastRowPlayed: Int? = nil
    @State private var lastColPlayed: Int? = nil
    @State private var lastPlayedWasRow: Bool = true

    // Practice
    @State private var userSelection: (row: Int, col: Int)?
    @State private var wasCorrect = false

    // Timing — 2s sweep (faster, because user is in control)
    private let sweepDuration: Double = 2.0

    var body: some View {
        VStack(spacing: 16) {
            header

            // Board
            TutorialBoardView(
                boardSize: boardSize,
                cellSize: cellSize,
                spacing: spacing,
                targetRow: targetRow,
                targetCol: targetCol,
                // lasers
                showRowLaser: phase == .rows || phase == .intersect,
                showColLaser: phase == .cols || phase == .intersect,
                rowProgress: rowProgress,
                colProgress: colProgress,
                // header highlights (top/left)
                highlightTopHeader: phase == .cols || phase == .intersect || phase == .framed || phase == .practice || phase == .feedback,
                highlightLeftHeader: phase == .rows || phase == .intersect || phase == .framed || phase == .practice || phase == .feedback,
                // row/col frame overlays
                highlightRowCells: phase == .framed,
                highlightColCells: phase == .framed,
                // intersection glow only in intersect
                enableIntersectionGlow: phase == .intersect
            )
            .frame(
                width: TutorialBoardView.pixelWidth(boardSize: boardSize, cellSize: cellSize, spacing: spacing),
                height: TutorialBoardView.pixelHeight(boardSize: boardSize, cellSize: cellSize, spacing: spacing)
            )

            // Annotation (Rows / Columns / Intersection)
            annotation

            // Buttons strips (Rows / Columns / Intersection keep their triggers)
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

            // Controls (Back • Repeat? • Next)
            controlBar
        }
        .padding()
        .navigationTitle(NSLocalizedString("tutorial_title", comment: "Tutorial"))
    }

    // MARK: Header (only show relevant labels)
    private var header: some View {
        VStack(spacing: 6) {
            switch phase {
            case .rows:
                Text(NSLocalizedString("tutorial_rows_title", comment: "Rows")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_rows_sub", comment: "Rows subtitle"))
                Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row label"), targetRow))
                    .foregroundStyle(.red)
                    .font(.subheadline)

            case .cols:
                Text(NSLocalizedString("tutorial_cols_title", comment: "Columns")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_cols_sub", comment: "Columns subtitle"))
                Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Column label"), targetCol))
                    .foregroundStyle(.blue)
                    .font(.subheadline)

            case .intersect:
                Text(NSLocalizedString("tutorial_intersect_title", comment: "Intersection")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_intersect_sub", comment: "Intersection subtitle"))
                HStack(spacing: 16) {
                    Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row"), targetRow)).foregroundStyle(.red)
                    Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Col"), targetCol)).foregroundStyle(.blue)
                }.font(.subheadline)

            case .framed:
                Text("Framed selection").font(.title3).bold()
                Text("We highlight a row and a column — notice their crossing cell.")

            case .practice:
                Text(NSLocalizedString("tutorial_practice_title", comment: "Practice")).font(.title3).bold()
                Text("Find the crossing cell for the given row and column.")

            case .feedback:
                Text(wasCorrect ? NSLocalizedString("tutorial_feedback_great", comment: "")
                                : NSLocalizedString("tutorial_feedback_not_quite", comment: ""))
                    .font(.title3).bold()
                Text(String(format: NSLocalizedString("tutorial_equation", comment: "r × c = product"),
                            targetRow, targetCol, targetRow * targetCol))
            }
        }
    }

    // MARK: Annotation under board
    private var annotation: some View {
        let (title, body): (String, String) = {
            switch phase {
            case .rows:
                return ("Now we practice rows",
                        "Imagine earthworm tunnels across the ground — lava rushes through the tunnels and the worm escapes sideways. That’s a horizontal sweep.")
            case .cols:
                return ("Now we practice columns",
                        "Imagine icicles falling from the roof — straight down in a line. That’s a vertical sweep.")
            case .intersect:
                return ("Intersections in the game",
                        "Multiple row and column numbers cross to give products. You’ll be asked to find a cell where a specific row and column meet.")
            default:
                return ("","")
            }
        }()

        return Group {
            if !title.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.headline)
                    Text(body).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            }
        }
    }

    // MARK: Row / Column triggers
    private var rowButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...boardSize, id: \.self) { r in
                Button("Row \(r)") { playRow(r) }
                    .buttonStyle(.bordered)
                    .disabled(isAnimating)
            }
        }
    }

    private var columnButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...boardSize, id: \.self) { c in
                Button("Column \(c)") { playCol(c) }
                    .buttonStyle(.bordered)
                    .disabled(isAnimating)
            }
        }
    }

    // MARK: Controls (Back • Repeat? • Next)
    private var controlBar: some View {
        HStack {
            // Back (always shown; disabled only on first page)
            Button("Back") { goBack() }
                .buttonStyle(.bordered)
                .disabled(isAnimating || isBackDisabled)

            Spacer()

            // Repeat (only for rows/cols/intersect)
            if showsRepeat {
                Button(NSLocalizedString("repeat", comment: "Repeat")) { repeatCurrent() }
                    .buttonStyle(.bordered)
                    .disabled(isAnimating || isRepeatDisabled)
                Spacer()
            }

            // Next
            Button(NSLocalizedString("next", comment: "Next")) { goNext() }
                .buttonStyle(.borderedProminent)
                .disabled(isAnimating || isNextDisabled)
        }
        .padding(.top, 2)
    }

    private var showsRepeat: Bool {
        phase == .rows || phase == .cols || phase == .intersect
    }

    private var isBackDisabled: Bool {
        phase == .rows
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
        case .intersect: return (lastRowPlayed == nil || lastColPlayed == nil) // need both to proceed
        case .framed:    return false
        case .practice:  return userSelection == nil // tap required
        case .feedback:  return false
        }
    }

    private func goBack() {
        switch phase {
        case .cols:      phase = .rows
        case .intersect: phase = .cols
        case .framed:    phase = .intersect
        case .practice:  phase = .framed
        case .feedback:  phase = .practice
        case .rows:      break
        }
    }

    private func goNext() {
        switch phase {
        case .rows:
            phase = .cols
        case .cols:
            phase = .intersect
        case .intersect:
            // move to framed step; keep current targets highlighted
            phase = .framed
        case .framed:
            // start practice challenge without frames
            newPracticeRound()
            phase = .practice
        case .practice:
            // after a tap, move to feedback
            if userSelection != nil { phase = .feedback }
        case .feedback:
            // another practice round
            newPracticeRound()
            phase = .practice
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

    // MARK: Row / Column playback
    private func playRow(_ r: Int) {
        // In rows/intersect we can set targetRow; in pure rows we must NOT force a column selection
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
        // In cols/intersect we can set targetCol; in pure cols we must NOT force a row selection
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

    // MARK: Practice flow
    private func newPracticeRound() {
        userSelection = nil
        wasCorrect = false
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
    }

    private func handleTap(row: Int, col: Int) {
        guard phase == .practice else { return }
        userSelection = (row, col)
        wasCorrect = (row == targetRow && col == targetCol)
    }
}
