//
//  TutorialBoardView.swift
//  Memul
//
//  Draws an NxN grid with ONLY top & left headers,
//  and renders row/column lasers centered on the chosen row/column.
//

import SwiftUI

struct TutorialBoardView: View {
    let boardSize: Int
    let cellSize: CGFloat
    let spacing: CGFloat

    let targetRow: Int
    let targetCol: Int

    // Which lasers to show
    let showRowLaser: Bool
    let showColLaser: Bool

    // Animation progress (0...1)
    let rowProgress: CGFloat
    let colProgress: CGFloat

    var body: some View {
        ZStack {
            gridWithHeaders
            if showRowLaser { rowLaser }
            if showColLaser { colLaser }
            if shouldShowIntersectionGlow {
                intersectionGlow
            }
        }
    }

    // MARK: Grid (top & left headers only)
    private var gridWithHeaders: some View {
        VStack(spacing: spacing) {
            // Top: corner + top numbers
            HStack(spacing: spacing) {
                headerCorner
                ForEach(1...boardSize, id: \.self) { c in topHeader(c) }
            }
            // Rows: left number + cells
            ForEach(1...boardSize, id: \.self) { r in
                HStack(spacing: spacing) {
                    leftHeader(r)
                    ForEach(1...boardSize, id: \.self) { c in cellAt(r, c) }
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

    private func cellAt(_ row: Int, _ col: Int) -> some View {
        let isIntersection = row == targetRow && col == targetCol && shouldShowIntersectionGlow
        return RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.gray, lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.18))
                    .overlay(
                        Group {
                            if isIntersection {
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

    // MARK: Lasers (centered precisely)

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

    // Intersection glow shows during intersect demo/pause when both beams passed the cell center
    private var shouldShowIntersectionGlow: Bool {
        // We infer that if both progresses have passed the intersection fraction, show glow.
        let rowPassed = rowProgress >= rowIntersectT
        let colPassed = colProgress >= colIntersectT
        return rowPassed && colPassed
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

    // MARK: Geometry (top-left origin is the whole board incl. headers)

    // Centers of grid cells (1...N)
    private func centerX(forCol col: Int) -> CGFloat {
        // colIndex 0 = left header, so first grid col is index 1
        return CGFloat(col) * (cellSize + spacing) + cellSize / 2
    }

    private func centerY(forRow row: Int) -> CGFloat {
        // rowIndex 0 = top header, so first grid row is index 1
        return CGFloat(row) * (cellSize + spacing) + cellSize / 2
    }

    // Inner edges of grid area (ignores headers), used for full-length sweeps
    private var gridLeftEdgeX: CGFloat { centerX(forCol: 1) - cellSize / 2 }
    private var gridRightEdgeX: CGFloat { centerX(forCol: boardSize) + cellSize / 2 }
    private var gridTopEdgeY: CGFloat { centerY(forRow: 1) - cellSize / 2 }
    private var gridBottomEdgeY: CGFloat { centerY(forRow: boardSize) + cellSize / 2 }

    // Intersection fractions along the sweeps
    private var rowIntersectT: CGFloat {
        let total = max(0.0001, gridRightEdgeX - gridLeftEdgeX)
        return max(0, min(1, (centerX(forCol: targetCol) - gridLeftEdgeX) / total))
    }

    private var colIntersectT: CGFloat {
        let total = max(0.0001, gridBottomEdgeY - gridTopEdgeY)
        return max(0, min(1, (centerY(forRow: targetRow) - gridTopEdgeY) / total))
    }

    // Public frame helpers (top+left headers only)
    static func pixelWidth(boardSize: Int, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        // columns = left header + N grid columns = (N + 1) cells
        // gaps = N (between header and first col + between grid cols)
        let items = CGFloat(boardSize + 1)
        let gaps = CGFloat(boardSize)
        return items * cellSize + gaps * spacing
    }

    static func pixelHeight(boardSize: Int, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        // rows = top header + N grid rows = (N + 1) cells
        // gaps = N (between header and first row + between grid rows)
        let items = CGFloat(boardSize + 1)
        let gaps = CGFloat(boardSize)
        return items * cellSize + gaps * spacing
    }

    // Math
    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * max(0, min(1, t))
    }
}
