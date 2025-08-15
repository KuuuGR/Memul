//
//  TutorialBoardView.swift
//  Memul
//
//  Top & left headers only; centered lasers; optional in-cell overlays.
//  Supports taps on headers and cells.
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

    // (deprecated in this version – kept for signature parity)
    let highlightRowCells: Bool
    let highlightColCells: Bool

    // glow flags
    let enableIntersectionGlow: Bool           // for the intersect demo (requires beams to cross)
    let practiceShowGlow: Bool                 // show product glow during Practice on correct tap

    // overlays
    let framedCorrectCell: (row: Int, col: Int)?
    let framedWrongCell: (row: Int, col: Int)?
    let practiceWrongCell: (row: Int, col: Int)?

    // taps
    var onTapTopHeader: ((Int) -> Void)? = nil
    var onTapLeftHeader: ((Int) -> Void)? = nil
    var onTapCell: ((Int, Int) -> Void)? = nil

    var body: some View {
        ZStack {
            grid
            if showRowLaser { rowLaser }
            if showColLaser { colLaser }
            // intersection/product glow:
            if (enableIntersectionGlow && lasersCrossed) || practiceShowGlow {
                intersectionGlow
            }
        }
    }

    // MARK: Grid (top & left headers only)
    private var grid: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                headerCorner
                ForEach(1...boardSize, id: \.self) { c in topHeader(c) }
            }
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
            .contentShape(Rectangle())
            .onTapGesture { onTapTopHeader?(col) }
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
            .contentShape(Rectangle())
            .onTapGesture { onTapLeftHeader?(row) }
    }

    private func cellAt(_ row: Int, _ col: Int) -> some View {
        let isFramedCorrect = framedCorrectCell?.row == row && framedCorrectCell?.col == col
        let isFramedWrong   = framedWrongCell?.row == row && framedWrongCell?.col == col
        let isPracticeWrong = practiceWrongCell?.row == row && practiceWrongCell?.col == col

        return RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.gray, lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.18))
                    .overlay(
                        ZStack {
                            // Framed step badges
                            if isFramedCorrect {
                                Text("✅")
                                    .font(.title).bold()
                                    .foregroundStyle(.green)
                                    .shadow(color: .black.opacity(0.5), radius: 1)
                            } else if isFramedWrong {
                                Text("❌")
                                    .font(.title).bold()
                                    .foregroundStyle(.red)
                                    .shadow(color: .black.opacity(0.5), radius: 1)
                            }
                            // Practice wrong tap badge (0.5s)
                            if isPracticeWrong {
                                Text("❌")
                                    .font(.title).bold()
                                    .foregroundStyle(.red)
                                    .shadow(color: .black.opacity(0.5), radius: 1)
                            }
                        }
                    )
            )
            .frame(width: cellSize, height: cellSize)
            .contentShape(Rectangle())
            .onTapGesture { onTapCell?(row, col) }
    }

    // MARK: Lasers (centered, full length)
    private var rowLaser: some View {
        let y = centerY(forRow: targetRow)
        let xStart = gridLeftEdgeX
        let xEnd = lerp(from: xStart, to: gridRightEdgeX, t: rowProgress)
        return LaserHorizontal(y: y, fromX: xStart, toX: xEnd)
            .accessibilityLabel("Row laser")
            .allowsHitTesting(false)
    }

    private var colLaser: some View {
        let x = centerX(forCol: targetCol)
        let yStart = gridTopEdgeY
        let yEnd = lerp(from: yStart, to: gridBottomEdgeY, t: colProgress)
        return LaserVertical(x: x, fromY: yStart, toY: yEnd)
            .accessibilityLabel("Column laser")
            .allowsHitTesting(false)
    }

    private var lasersCrossed: Bool {
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

    // MARK: Geometry
    private func centerX(forCol col: Int) -> CGFloat {
        // col 0 = left header; first grid col is 1
        return CGFloat(col) * (cellSize + spacing) + cellSize / 2
    }
    private func centerY(forRow row: Int) -> CGFloat {
        // row 0 = top header; first grid row is 1
        return CGFloat(row) * (cellSize + spacing) + cellSize / 2
    }

    // inner grid edges (exclude headers)
    private var gridLeftEdgeX: CGFloat { centerX(forCol: 1) - cellSize / 2 }
    private var gridRightEdgeX: CGFloat { centerX(forCol: boardSize) + cellSize / 2 }
    private var gridTopEdgeY: CGFloat { centerY(forRow: 1) - cellSize / 2 }
    private var gridBottomEdgeY: CGFloat { centerY(forRow: boardSize) + cellSize / 2 }

    private var rowIntersectT: CGFloat {
        let total = max(0.0001, gridRightEdgeX - gridLeftEdgeX)
        return max(0, min(1, (centerX(forCol: targetCol) - gridLeftEdgeX) / total))
    }
    private var colIntersectT: CGFloat {
        let total = max(0.0001, gridBottomEdgeY - gridTopEdgeY)
        return max(0, min(1, (centerY(forRow: targetRow) - gridTopEdgeY) / total))
    }

    // Public sizing helpers
    static func pixelWidth(boardSize: Int, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        let items = CGFloat(boardSize + 1) // left header + N columns
        let gaps = CGFloat(boardSize)
        return items * cellSize + gaps * spacing
    }
    static func pixelHeight(boardSize: Int, cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        let items = CGFloat(boardSize + 1) // top header + N rows
        let gaps = CGFloat(boardSize)
        return items * cellSize + gaps * spacing
    }

    // Math
    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * max(0, min(1, t))
    }
}
