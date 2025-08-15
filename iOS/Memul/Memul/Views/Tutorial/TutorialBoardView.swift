//
//  TutorialBoardView.swift
//  Memul
//
//  Grid with ONLY top & left headers.
//  Lasers run through the exact centers of cells and sweep the full grid.
//

import SwiftUI

struct TutorialBoardView: View {
    let boardSize: Int
    let cellSize: CGFloat
    let spacing: CGFloat

    let targetRow: Int
    let targetCol: Int

    // lasers
    let showRowLaser: Bool
    let showColLaser: Bool
    let rowProgress: CGFloat
    let colProgress: CGFloat

    // header highlights
    let highlightTopHeader: Bool
    let highlightLeftHeader: Bool

    // frame overlays
    let highlightRowCells: Bool
    let highlightColCells: Bool

    // glow
    let enableIntersectionGlow: Bool

    var body: some View {
        ZStack {
            grid
            // optional row/col frames
            if highlightRowCells { rowFrame }
            if highlightColCells { colFrame }
            // lasers
            if showRowLaser { rowLaser }
            if showColLaser { colLaser }
            // cross glow
            if enableIntersectionGlow && lasersCrossed { intersectionGlow }
        }
    }

    // MARK: Grid (top & left headers only)
    private var grid: some View {
        VStack(spacing: spacing) {
            // top header row
            HStack(spacing: spacing) {
                headerCorner
                ForEach(1...boardSize, id: \.self) { c in topHeader(c) }
            }
            // grid rows
            ForEach(1...boardSize, id: \.self) { r in
                HStack(spacing: spacing) {
                    leftHeader(r)
                    ForEach(1...boardSize, id: \.self) { c in
                        cellAt(r, c)
                    }
                }
            }
        }
    }

    private var headerCorner: some View {
        Color.clear.frame(width: cellSize, height: cellSize)
    }

    private func topHeader(_ col: Int) -> some View {
        Text("\(col)")
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(highlightTopHeader && col == targetCol ? Color.blue : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func leftHeader(_ row: Int) -> some View {
        Text("\(row)")
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .background(Color(UIColor.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(highlightLeftHeader && row == targetRow ? Color.red : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func cellAt(_ row: Int, _ col: Int) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(borderColor(row: row, col: col), lineWidth: borderWidth(row: row, col: col))
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.18)))
            .frame(width: cellSize, height: cellSize)
    }

    private func borderColor(row: Int, col: Int) -> Color {
        if highlightRowCells && row == targetRow { return .yellow }
        if highlightColCells && col == targetCol { return .yellow }
        return .gray
    }

    private func borderWidth(row: Int, col: Int) -> CGFloat {
        if (highlightRowCells && row == targetRow) || (highlightColCells && col == targetCol) { return 3 }
        return 1
    }

    // MARK: Lasers (centered, full length)

    private var rowLaser: some View {
        let y = centerY(forRow: targetRow)
        let xStart = gridLeftEdgeX
        let xEnd = lerp(from: xStart, to: gridRightEdgeX, t: rowProgress)
        return LaserHorizontal(y: y, fromX: xStart, toX: xEnd)
            .accessibilityLabel("Row laser")
    }

    private var colLaser: some View {
        let x = centerX(forCol: targetCol)
        let yStart = gridTopEdgeY
        let yEnd = lerp(from: yStart, to: gridBottomEdgeY, t: colProgress)
        return LaserVertical(x: x, fromY: yStart, toY: yEnd)
            .accessibilityLabel("Column laser")
    }

    private var lasersCrossed: Bool {
        // both beams have passed the crossing point
        rowProgress >= rowIntersectT && colProgress >= colIntersectT
    }

    private var intersectionGlow: some View {
        let x = centerX(forCol: targetCol)
        let y = centerY(forRow: targetRow)
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
    }

    // MARK: Frame overlays
    private var rowFrame: some View {
        let y = centerY(forRow: targetRow)
        return RoundedRectangle(cornerRadius: 0)
            .stroke(Color.yellow, lineWidth: 3)
            .frame(width: gridWidth, height: cellSize)
            .position(x: gridMidX, y: y)
            .allowsHitTesting(false)
            .opacity(0.4)
    }

    private var colFrame: some View {
        let x = centerX(forCol: targetCol)
        return RoundedRectangle(cornerRadius: 0)
            .stroke(Color.yellow, lineWidth: 3)
            .frame(width: cellSize, height: gridHeight)
            .position(x: x, y: gridMidY)
            .allowsHitTesting(false)
            .opacity(0.4)
    }

    // MARK: Geometry (top-left origin includes headers)
    private func centerX(forCol col: Int) -> CGFloat {
        // col index 0 is the left header; first grid col is 1
        return CGFloat(col) * (cellSize + spacing) + cellSize / 2
    }

    private func centerY(forRow row: Int) -> CGFloat {
        // row index 0 is the top header; first grid row is 1
        return CGFloat(row) * (cellSize + spacing) + cellSize / 2
    }

    // Inner grid edges (exclude headers)
    private var gridLeftEdgeX: CGFloat { centerX(forCol: 1) - cellSize / 2 }
    private var gridRightEdgeX: CGFloat { centerX(forCol: boardSize) + cellSize / 2 }
    private var gridTopEdgeY: CGFloat { centerY(forRow: 1) - cellSize / 2 }
    private var gridBottomEdgeY: CGFloat { centerY(forRow: boardSize) + cellSize / 2 }

    private var gridWidth: CGFloat { gridRightEdgeX - gridLeftEdgeX }
    private var gridHeight: CGFloat { gridBottomEdgeY - gridTopEdgeY }
    private var gridMidX: CGFloat { (gridLeftEdgeX + gridRightEdgeX) / 2 }
    private var gridMidY: CGFloat { (gridTopEdgeY + gridBottomEdgeY) / 2 }

    private var rowIntersectT: CGFloat {
        let total = max(0.0001, gridRightEdgeX - gridLeftEdgeX)
        return max(0, min(1, (centerX(forCol: targetCol) - gridLeftEdgeX) / total))
    }

    private var colIntersectT: CGFloat {
        let total = max(0.0001, gridBottomEdgeY - gridTopEdgeY)
        return max(0, min(1, (centerY(forRow: targetRow) - gridTopEdgeY) / total))
    }

    // Public helpers for parent sizing
    static func pixelWidth(boardSize: Int, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        // columns = left header + N grid columns
        let items = CGFloat(boardSize + 1)
        let gaps = CGFloat(boardSize)
        return items * cellSize + gaps * spacing
    }

    static func pixelHeight(boardSize: Int, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        // rows = top header + N grid rows
        let items = CGFloat(boardSize + 1)
        let gaps = CGFloat(boardSize)
        return items * cellSize + gaps * spacing
    }

    // Math
    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * max(0, min(1, t))
    }
}
