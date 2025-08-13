//
//  TutorialView.swift
//  Memul
//
//  Created by KuuuGR on 08/08/2025.
//
//  Changes:
//  - Swap laser colors so ROW (horizontal) is RED and COLUMN (vertical) is BLUE.
//  - Slow down animations by increasing `sweepDuration` and `pauseAfterDemo`.
//  - In Intersection demo, lasers sweep ACROSS the whole grid (don’t stop at the crossing).
//  - Show intersection glow AS SOON AS both lasers have reached the crossing point during the sweep.
//

import SwiftUI

struct TutorialView: View {
    private let boardSize = 4
    private let cellSize: CGFloat = 42
    private let spacing: CGFloat = 4

    private enum Phase { case rowsDemo, colsDemo, intersectDemo, intersectPause, practice, feedback }

    @State private var phase: Phase = .rowsDemo
    @State private var demosLeftRows = 2
    @State private var demosLeftCols = 2
    @State private var demosLeftIntersect = 3

    @State private var targetRow = 1
    @State private var targetCol = 1

    @State private var rowProgress: CGFloat = 0
    @State private var colProgress: CGFloat = 0

    @State private var userSelection: (row: Int, col: Int)?
    @State private var wasCorrect = false

    private let sweepDuration = 1.05
    private let pauseAfterDemo = 0.6

    var body: some View {
        VStack(spacing: 16) {
            header
            ZStack {
                gridWithHeaders
                rowLaser
                colLaser
                if shouldShowIntersectionGlow { intersectionGlow }
            }
            .frame(width: gridPixelWidth, height: gridPixelHeight)
            footer
        }
        .padding()
        .navigationTitle("Tutorial")
        .onAppear { startRowsDemo() }
    }

    private var header: some View {
        VStack(spacing: 6) {
            switch phase {
            case .rowsDemo:
                Text("Rows").font(.title3).bold()
                Text("Watch the horizontal line sweep a row.")
            case .colsDemo:
                Text("Columns").font(.title3).bold()
                Text("Watch the vertical line sweep a column.")
            case .intersectDemo, .intersectPause:
                Text("Intersection").font(.title3).bold()
                Text("Where a row meets a column: row × column.")
            case .practice:
                Text("Try it!").font(.title3).bold()
                Text("Tap the cell where the lasers will cross.")
            case .feedback:
                Text(wasCorrect ? "Great!" : "Not quite").font(.title3).bold()
                Text("\(targetRow) × \(targetCol) = \(targetRow * targetCol)")
            }
            HStack(spacing: 16) {
                Text("Row: \(targetRow)").foregroundStyle(.red)
                Text("Column: \(targetCol)").foregroundStyle(.blue)
            }.font(.subheadline)
        }
    }

    private var footer: some View {
        HStack {
            if phase == .practice || phase == .feedback {
                Button("Next") { nextPracticeRound() }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Skip to Practice") { phase = .practice }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

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
            HStack(spacing: spacing) {
                headerCorner
                ForEach(1...boardSize, id: \.self) { c in topHeader(c) }
                headerCorner
            }
            ForEach(1...boardSize, id: \.self) { r in
                HStack(spacing: spacing) {
                    leftHeader(r)
                    ForEach(1...boardSize, id: \.self) { c in
                        cellAt(r, c).onTapGesture { handleTap(row: r, col: c) }
                    }
                    rightHeader(r)
                }
            }
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
        return RoundedRectangle(cornerRadius: 8)
            .strokeBorder(highlighted ? Color.yellow : Color.gray, lineWidth: highlighted ? 3 : 1)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.18)))
            .frame(width: cellSize, height: cellSize)
    }

    private var shouldHighlightRowCol: Bool {
        (phase == .intersectPause || phase == .feedback) || (phase == .intersectDemo && shouldShowIntersectionGlow)
    }

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

    private var intersectionGlow: some View {
        let x = columnCenterX(colIndex: targetCol)
        let y = rowCenterY(rowIndex: targetRow)
        return ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.35))
                .frame(width: cellSize * 0.9, height: cellSize * 0.9)
            Text("\(targetRow * targetCol)")
                .font(.headline)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 1.5)
        }
        .position(x: x, y: y)
        .allowsHitTesting(false)
        .transition(.scale.combined(with: .opacity))
    }

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

    private func startRowsDemo() {
        phase = .rowsDemo
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
        rowProgress = 0
        withAnimation(.easeInOut(duration: sweepDuration)) { rowProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + pauseAfterDemo) {
            if demosLeftRows > 1 { demosLeftRows -= 1; startRowsDemo() }
            else { demosLeftRows = 0; startColsDemo() }
        }
    }

    private func startColsDemo() {
        phase = .colsDemo
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
        colProgress = 0
        withAnimation(.easeInOut(duration: sweepDuration)) { colProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + pauseAfterDemo) {
            if demosLeftCols > 1 { demosLeftCols -= 1; startColsDemo() }
            else { demosLeftCols = 0; startIntersectDemo() }
        }
    }

    private func startIntersectDemo() {
        phase = .intersectDemo
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
        rowProgress = 0
        colProgress = 0
        withAnimation(.easeInOut(duration: sweepDuration)) { rowProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: sweepDuration)) { colProgress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + sweepDuration + 0.20) {
            withAnimation { phase = .intersectPause }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if demosLeftIntersect > 1 { demosLeftIntersect -= 1; startIntersectDemo() }
                else { demosLeftIntersect = 0; phase = .practice }
            }
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

    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * max(0, min(1, t))
    }
}

private struct LaserHorizontal: View {
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
