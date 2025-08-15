//
//  TutorialView.swift
//  Memul
//
//  Created by KuuuGR on 08/08/2025.
//

import SwiftUI

struct TutorialView: View {
    // Grid config
    private let boardSize = 4
    private let cellSize: CGFloat = 42
    private let spacing: CGFloat = 4

    // Tutorial phases
    private enum Phase {
        case rowsDemo, rowsPause
        case colsDemo, colsPause
        case intersectDemo, intersectPause
        case practice, feedback
    }

    @State private var phase: Phase = .rowsDemo

    // Targets
    @State private var targetRow = 1
    @State private var targetCol = 1

    // Animation progress (0..1)
    @State private var rowProgress: CGFloat = 0
    @State private var colProgress: CGFloat = 0

    // Manual controls
    @State private var isAnimating = false
    @State private var lastRowPlayed: Int? = nil
    @State private var lastColPlayed: Int? = nil

    // Practice (kept for future)
    @State private var userSelection: (row: Int, col: Int)?
    @State private var wasCorrect = false

    // Tuning (speed up by one-third from 4.20s → 2.80s)
    private let sweepDuration = 2.80
    private let pauseAfterDemo = 0.6

    var body: some View {
        VStack(spacing: 16) {
            header

            ZStack {
                // Board + lasers
                TutorialBoardView(
                    boardSize: boardSize,
                    cellSize: cellSize,
                    spacing: spacing,
                    targetRow: targetRow,
                    targetCol: targetCol,
                    showRowLaser: phase == .rowsDemo || phase == .intersectDemo,
                    showColLaser: phase == .colsDemo || phase == .intersectDemo,
                    rowProgress: rowProgress,
                    colProgress: colProgress
                )
                .frame(
                    width: TutorialBoardView.pixelWidth(boardSize: boardSize, cellSize: cellSize, spacing: spacing),
                    height: TutorialBoardView.pixelHeight(boardSize: boardSize, cellSize: cellSize, spacing: spacing)
                )
            }

            // Annotation BELOW the board
            annotationView

            // Row/Column trigger buttons + controls
            if phase == .rowsDemo || phase == .rowsPause {
                rowButtons
                rowsColsControlBar
            } else if phase == .colsDemo || phase == .colsPause {
                columnButtons
                rowsColsControlBar
            } else {
                // Fallback footer for other phases
                footerOtherPhases
            }
        }
        .padding()
        .navigationTitle(NSLocalizedString("tutorial_title", comment: "Tutorial"))
    }

    // MARK: Header (only show relevant labels)
    private var header: some View {
        VStack(spacing: 6) {
            switch phase {
            case .rowsDemo, .rowsPause:
                Text(NSLocalizedString("tutorial_rows_title", comment: "Rows")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_rows_sub", comment: "Rows subtitle"))
                Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row label"), targetRow))
                    .foregroundStyle(.red)
                    .font(.subheadline)

            case .colsDemo, .colsPause:
                Text(NSLocalizedString("tutorial_cols_title", comment: "Columns")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_cols_sub", comment: "Columns subtitle"))
                Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Column label"), targetCol))
                    .foregroundStyle(.blue)
                    .font(.subheadline)

            case .intersectDemo, .intersectPause:
                Text(NSLocalizedString("tutorial_intersect_title", comment: "Intersection")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_intersect_sub", comment: "Intersection subtitle"))
                HStack(spacing: 16) {
                    Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row"), targetRow)).foregroundStyle(.red)
                    Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Col"), targetCol)).foregroundStyle(.blue)
                }.font(.subheadline)

            case .practice:
                Text(NSLocalizedString("tutorial_practice_title", comment: "Practice")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_practice_sub", comment: "Practice subtitle"))

            case .feedback:
                Text(wasCorrect ? NSLocalizedString("tutorial_feedback_great", comment: "") :
                                  NSLocalizedString("tutorial_feedback_not_quite", comment: ""))
                    .font(.title3).bold()
                Text(String(format: NSLocalizedString("tutorial_equation", comment: "r × c = product"),
                            targetRow, targetCol, targetRow * targetCol))
            }
        }
    }

    // MARK: Annotation (below board)
    private var annotationView: some View {
        let title: String
        let body: String
        switch phase {
        case .rowsDemo, .rowsPause:
            title = "Now we practice rows"
            body  = "Imagine earthworm tunnels across the ground — lava rushes through and the worm escapes sideways. That’s a horizontal sweep."
        case .colsDemo, .colsPause:
            title = "Now we practice columns"
            body  = "Imagine icicles falling from the roof — straight down in a line. That’s a vertical sweep."
        default:
            title = ""; body = ""
        }

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

    // MARK: Row / Column button strips
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

    // MARK: Rows/Cols controls (Back • Repeat • Next)
    private var rowsColsControlBar: some View {
        HStack {
            // Back (left)
            Button("Back") { goBack() }
                .buttonStyle(.bordered)
                .disabled(isAnimating || isBackDisabled)

            Spacer()

            // Repeat (center)
            Button(NSLocalizedString("repeat", comment: "Repeat")) { repeatCurrent() }
                .buttonStyle(.bordered)
                .disabled(isAnimating || isRepeatDisabled)

            Spacer()

            // Next (right)
            Button(NSLocalizedString("next", comment: "Next")) { goNextFromRowsCols() }
                .buttonStyle(.borderedProminent)
                .disabled(isAnimating || isNextDisabled)
        }
        .padding(.top, 2)
    }

    private var isBackDisabled: Bool {
        switch phase {
        case .rowsDemo, .rowsPause: return true     // first page
        case .colsDemo, .colsPause: return false
        default: return true
        }
    }

    private var isRepeatDisabled: Bool {
        switch phase {
        case .rowsDemo, .rowsPause: return lastRowPlayed == nil
        case .colsDemo, .colsPause: return lastColPlayed == nil
        default: return true
        }
    }

    private var isNextDisabled: Bool {
        switch phase {
        case .rowsDemo, .rowsPause: return lastRowPlayed == nil
        case .colsDemo, .colsPause: return lastColPlayed == nil
        default: return true
        }
    }

    private func goBack() {
        switch phase {
        case .colsDemo, .colsPause:
            phase = .rowsPause
        default: break
        }
    }

    private func repeatCurrent() {
        switch phase {
        case .rowsDemo, .rowsPause:
            if let r = lastRowPlayed { playRow(r) }
        case .colsDemo, .colsPause:
            if let c = lastColPlayed { playCol(c) }
        default: break
        }
    }

    private func goNextFromRowsCols() {
        switch phase {
        case .rowsDemo, .rowsPause:
            phase = .colsDemo
        case .colsDemo, .colsPause:
            startIntersectDemo(randomizeTarget: true)
        default:
            break
        }
    }

    // MARK: Other phases footer (unchanged logic for intersect/practice)
    private var footerOtherPhases: some View {
        HStack {
            switch phase {
            case .intersectPause:
                Button(NSLocalizedString("repeat", comment: "Repeat")) { startIntersectDemo(randomizeTarget: false) }
                    .buttonStyle(.bordered)
                Spacer()
                Button(NSLocalizedString("next", comment: "Next")) { phase = .practice }
                    .buttonStyle(.borderedProminent)

            case .practice, .feedback:
                Spacer()
                Button(NSLocalizedString("next", comment: "Next")) { /* future practice flow */ }
                    .buttonStyle(.borderedProminent)

            default:
                Spacer()
                Button(NSLocalizedString("skip_to_practice", comment: "Skip")) { phase = .practice }
                    .buttonStyle(.bordered)
            }
        }
        .padding(.top, 4)
    }

    // MARK: Manual play actions (Rows / Cols)
    private func playRow(_ r: Int) {
        phase = .rowsDemo
        lastRowPlayed = r
        targetRow = r
        rowProgress = 0
        isAnimating = true
        withAnimation(.easeInOut(duration: sweepDuration)) { rowProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + 0.05) {
            isAnimating = false
            phase = .rowsPause
        }
    }

    private func playCol(_ c: Int) {
        phase = .colsDemo
        lastColPlayed = c
        targetCol = c
        colProgress = 0
        isAnimating = true
        withAnimation(.easeInOut(duration: sweepDuration)) { colProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + 0.05) {
            isAnimating = false
            phase = .colsPause
        }
    }

    // MARK: Intersection demo
    private func startIntersectDemo(randomizeTarget: Bool) {
        if randomizeTarget {
            targetRow = Int.random(in: 1...boardSize)
            targetCol = Int.random(in: 1...boardSize)
        }
        phase = .intersectDemo
        rowProgress = 0
        colProgress = 0
        withAnimation(.easeInOut(duration: sweepDuration)) { rowProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: sweepDuration)) { colProgress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + 0.20) {
            phase = .intersectPause
        }
    }
}
