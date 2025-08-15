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
    private enum Phase { case rowsDemo, rowsPause, colsDemo, colsPause, intersectDemo, intersectPause, practice, feedback }

    @State private var phase: Phase = .rowsDemo

    // Targets
    @State private var targetRow = 1
    @State private var targetCol = 1

    // Animation progress (0..1)
    @State private var rowProgress: CGFloat = 0
    @State private var colProgress: CGFloat = 0

    // Practice
    @State private var userSelection: (row: Int, col: Int)?
    @State private var wasCorrect = false

    // Manual controls
    @State private var isAnimating = false
    @State private var lastRowPlayed: Int? = nil
    @State private var lastColPlayed: Int? = nil

    // Tuning (4× slower)
    private let sweepDuration = 4.20   // previously 1.05
    private let pauseAfterDemo = 0.6   // small pause after completion (kept for intersect)

    var body: some View {
        VStack(spacing: 16) {
            header

            ZStack {
                gridWithHeaders
                rowLaser
                colLaser
            }
            .frame(width: gridPixelWidth, height: gridPixelHeight)

            // === Annotation goes directly UNDER the board ===
            annotationView

            // === Rows/Columns trigger buttons under annotation ===
            if phase == .rowsDemo || phase == .rowsPause {
                rowButtons
                controlBarRowsCols
            } else if phase == .colsDemo || phase == .colsPause {
                columnButtons
                controlBarRowsCols
            } else {
                // Fallback footer for other phases (unchanged behavior)
                footerOtherPhases
            }
        }
        .padding()
        .navigationTitle(NSLocalizedString("tutorial_title", comment: "Tutorial screen title"))
        // NOTE: no auto-run; user taps Row/Column buttons to animate
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            switch phase {
            case .rowsDemo, .rowsPause:
                Text(NSLocalizedString("tutorial_rows_title", comment: "Rows title")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_rows_sub", comment: "Rows subtitle"))
            case .colsDemo, .colsPause:
                Text(NSLocalizedString("tutorial_cols_title", comment: "Columns title")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_cols_sub", comment: "Columns subtitle"))
            case .intersectDemo, .intersectPause:
                Text(NSLocalizedString("tutorial_intersect_title", comment: "Intersection title")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_intersect_sub", comment: "Intersection subtitle"))
            case .practice:
                Text(NSLocalizedString("tutorial_practice_title", comment: "Practice title")).font(.title3).bold()
                Text(NSLocalizedString("tutorial_practice_sub", comment: "Practice subtitle"))
            case .feedback:
                Text(wasCorrect ? NSLocalizedString("tutorial_feedback_great", comment: "Great") : NSLocalizedString("tutorial_feedback_not_quite", comment: "Not quite")).font(.title3).bold()
                Text(String(format: NSLocalizedString("tutorial_equation", comment: "r × c = product"), targetRow, targetCol, targetRow * targetCol))
            }
            HStack(spacing: 16) {
                Text(String(format: NSLocalizedString("tutorial_row_label", comment: "Row label"), targetRow)).foregroundStyle(.red)
                Text(String(format: NSLocalizedString("tutorial_col_label", comment: "Column label"), targetCol)).foregroundStyle(.blue)
            }.font(.subheadline)
        }
    }

    // MARK: Annotation (below board)

    private var annotationView: some View {
        let title: String
        let body: String
        switch phase {
        case .rowsDemo, .rowsPause:
            title = "Now we practice rows"
            body = "Imagine earthworm tunnels across the ground—lava rushes through the tunnels and the worm escapes sideways. That’s a horizontal sweep."
        case .colsDemo, .colsPause:
            title = "Now we practice columns"
            body = "Imagine icicles falling from the roof—straight down in a line. That’s a vertical sweep."
        default:
            title = ""
            body = ""
        }

        return Group {
            if !title.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.headline)
                    Text(body).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
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

    // MARK: Controls (Repeat left, Next right) — under row/column buttons

    private var controlBarRowsCols: some View {
        HStack {
            Button(NSLocalizedString("repeat", comment: "Repeat button")) { repeatCurrentAnimation() }
                .buttonStyle(.bordered)
                .disabled(isAnimating || repeatDisabled)

            Spacer()

            Button(NSLocalizedString("next", comment: "Next button")) { nextFromRowsCols() }
                .buttonStyle(.borderedProminent)
                .disabled(isAnimating || nextDisabled)
        }
        .padding(.top, 2)
    }

    private var repeatDisabled: Bool {
        switch phase {
        case .rowsDemo, .rowsPause: return lastRowPlayed == nil
        case .colsDemo, .colsPause: return lastColPlayed == nil
        default: return true
        }
    }

    private var nextDisabled: Bool {
        switch phase {
        case .rowsDemo, .rowsPause: return lastRowPlayed == nil
        case .colsDemo, .colsPause: return lastColPlayed == nil
        default: return true
        }
    }

    private func nextFromRowsCols() {
        switch phase {
        case .rowsDemo, .rowsPause:
            phase = .colsDemo
        case .colsDemo, .colsPause:
            startIntersectDemo(randomizeTarget: true) // keep your original intersection step
        default:
            break
        }
    }

    // MARK: Fallback footer for other phases (kept from your version)

    private var footerOtherPhases: some View {
        HStack {
            switch phase {
            case .intersectPause:
                Button(NSLocalizedString("repeat", comment: "Repeat button")) { repeatCurrentAnimation() }
                    .buttonStyle(.bordered)
                Button(NSLocalizedString("next", comment: "Next button")) { nextFromPause() }
                    .buttonStyle(.borderedProminent)
            case .practice, .feedback:
                Button(NSLocalizedString("next", comment: "Next button")) { nextPracticeRound() }
                    .buttonStyle(.borderedProminent)
            default:
                Button(NSLocalizedString("skip_to_practice", comment: "Skip to Practice")) { phase = .practice }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: Grid

    private var gridPixelWidth: CGFloat {
        let items = CGFloat(boardSize + 2)
        let gaps = CGFloat(boardSize + 1 + 2)
        return items * cellSize + gaps * spacing
    }

    private var gridPixelHeight: CGFloat {
        let items = CGFloat(boardSize + 2)
        let gaps = CGFloat(boardSize + 1 + 2)
        return items * cellSize + gaps * spacing
    }

    private var gridWithHeaders: some View {
        VStack(spacing: spacing) {
            // top numbers
            HStack(spacing: spacing) {
                headerCorner
                ForEach(1...boardSize, id: \.self) { c in topHeader(c) }
                headerCorner
            }
            // rows
            ForEach(1...boardSize, id: \.self) { r in
                HStack(spacing: spacing) {
                    leftHeader(r)
                    ForEach(1...boardSize, id: \.self) { c in
                        cellAt(r, c).onTapGesture { handleTap(row: r, col: c) }
                    }
                    rightHeader(r)
                }
            }
            // bottom numbers
            HStack(spacing: spacing) {
                headerCorner
                ForEach(1...boardSize, id: \.self) { c in bottomHeader(c) }
                headerCorner
            }
        }
    }

    private var headerCorner: some View { Color.clear.frame(width: cellSize, height: cellSize) }

    private func topHeader(_ col: Int) -> some View {
        Text("\(col)")
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(col == targetCol ? Color.blue : .clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func bottomHeader(_ col: Int) -> some View {
        Text("\(col)")
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(col == targetCol ? Color.blue : .clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func leftHeader(_ row: Int) -> some View {
        Text("\(row)")
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(row == targetRow ? Color.red : .clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func rightHeader(_ row: Int) -> some View {
        Text("\(row)")
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(row == targetRow ? Color.red : .clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func cellAt(_ row: Int, _ col: Int) -> some View {
        let highlighted = shouldHighlightRowCol && (row == targetRow || col == targetCol)
        let isIntersection = row == targetRow && col == targetCol

        return RoundedRectangle(cornerRadius: 8)
            .strokeBorder(highlighted ? Color.yellow : Color.gray, lineWidth: highlighted ? 3 : 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.18))
                    .overlay(
                        // Intersection number glow — centered in this cell
                        Group {
                            if isIntersection && shouldShowIntersectionGlow {
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.35))
                                        .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                                    Text("\(targetRow * targetCol)")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .shadow(color: .black.opacity(0.7), radius: 1.5)
                                }
                            }
                        }
                    )
            )
            .frame(width: cellSize, height: cellSize)
    }

    private var shouldHighlightRowCol: Bool {
        (phase == .intersectPause || phase == .feedback) || (phase == .intersectDemo && shouldShowIntersectionGlow)
    }

    // MARK: Lasers

    @ViewBuilder private var rowLaser: some View {
        if phase == .rowsDemo || phase == .intersectDemo {
            let y = rowCenterY(rowIndex: targetRow)
            let xStart = leftHeaderRightX
            let xEndAcross = rightHeaderLeftX
            let endX = lerp(from: xStart, to: xEndAcross, t: rowProgress)
            LaserHorizontal(y: y, fromX: xStart, toX: endX)
        }
    }

    @ViewBuilder private var colLaser: some View {
        if phase == .colsDemo || phase == .intersectDemo {
            let x = columnCenterX(colIndex: targetCol)
            let yStart = topHeaderBottomY
            let yEndAcross = bottomHeaderTopY
            let endY = lerp(from: yStart, to: yEndAcross, t: colProgress)
            LaserVertical(x: x, fromY: yStart, toY: endY)
        }
    }

    private var shouldShowIntersectionGlow: Bool {
        if phase == .intersectPause || phase == .feedback { return true }
        guard phase == .intersectDemo else { return false }
        return rowProgress >= rowIntersectT && colProgress >= colIntersectT
    }

    // MARK: Geometry helpers

    private func rowCenterY(rowIndex: Int) -> CGFloat {
        let rowsBefore = CGFloat(rowIndex)
        return rowsBefore * (cellSize + spacing) + cellSize / 2
    }

    private func columnCenterX(colIndex: Int) -> CGFloat {
        let colsBefore = CGFloat(colIndex)
        return colsBefore * (cellSize + spacing) + cellSize / 2
    }

    private var topHeaderBottomY: CGFloat { rowCenterY(rowIndex: 0) + cellSize / 2 }
    private var bottomHeaderTopY: CGFloat { rowCenterY(rowIndex: boardSize + 1) - cellSize / 2 }
    private var leftHeaderRightX: CGFloat { columnCenterX(colIndex: 0) + cellSize / 2 }
    private var rightHeaderLeftX: CGFloat { columnCenterX(colIndex: boardSize + 1) - cellSize / 2 }

    // Fractions of sweep where the intersection lies (used to reveal glow mid-sweep)
    private var rowIntersectT: CGFloat {
        let xStart = leftHeaderRightX
        let xEndAcross = rightHeaderLeftX
        let xCross = columnCenterX(colIndex: targetCol)
        let total = max(0.0001, xEndAcross - xStart)
        return max(0, min(1, (xCross - xStart) / total))
    }

    private var colIntersectT: CGFloat {
        let yStart = topHeaderBottomY
        let yEndAcross = bottomHeaderTopY
        let yCross = rowCenterY(rowIndex: targetRow)
        let total = max(0.0001, yEndAcross - yStart)
        return max(0, min(1, (yCross - yStart) / total))
    }

    // MARK: Manual play actions

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

    private func repeatCurrentAnimation() {
        switch phase {
        case .rowsPause:
            if let r = lastRowPlayed { playRow(r) }
        case .colsPause:
            if let c = lastColPlayed { playCol(c) }
        case .intersectPause:
            startIntersectDemo(randomizeTarget: false)
        default: break
        }
    }

    private func nextFromPause() {
        switch phase {
        case .intersectPause:
            phase = .practice
        default: break
        }
    }

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

    private func nextPracticeRound() {
        phase = .practice
        userSelection = nil
        wasCorrect = false
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
    }

    private func handleTap(row: Int, col: Int) {
        guard phase == .practice else { return }
        userSelection = (row, col)
        wasCorrect = (row == targetRow && col == targetCol)
        withAnimation { phase = .feedback }
    }

    // MARK: Math
    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * max(0, min(1, t))
    }
}

// MARK: Laser shapes (COLORS SWAPPED)

private struct LaserHorizontal: View {
    // ROW laser — RED
    let y: CGFloat
    let fromX: CGFloat
    let toX: CGFloat

    var body: some View {
        let width = max(0, toX - fromX)
        RoundedRectangle(cornerRadius: 3)
            .fill(LinearGradient(colors: [.red.opacity(0.1), .red, .white, .red, .red.opacity(0.1)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(width: width, height: 6)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.7), lineWidth: 0.5))
            .position(x: fromX + width / 2, y: y)
            .shadow(color: .red.opacity(0.6), radius: 4)
            .allowsHitTesting(false)
    }
}

private struct LaserVertical: View {
    // COLUMN laser — BLUE
    let x: CGFloat
    let fromY: CGFloat
    let toY: CGFloat

    var body: some View {
        let height = max(0, toY - fromY)
        RoundedRectangle(cornerRadius: 3)
            .fill(LinearGradient(colors: [.blue.opacity(0.1), .blue, .white, .blue, .blue.opacity(0.1)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 6, height: height)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.7), lineWidth: 0.5))
            .position(x: x, y: fromY + height / 2)
            .shadow(color: .blue.opacity(0.6), radius: 4)
            .allowsHitTesting(false)
    }
}
