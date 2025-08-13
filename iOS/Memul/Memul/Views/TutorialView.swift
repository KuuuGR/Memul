//
//  TutorialView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 08/08/2025.
//

import SwiftUI

/// A simple, animated tutorial that teaches:
/// - Rows vs Columns
/// - Coordinate intersection
/// - Multiplication value at the intersection
///
/// Flow:
/// 1) Auto-demo plays N examples (icicle + flame animate to meet).
/// 2) Switches to "Try it yourself": user taps the intersection cell.
/// 3) Immediate feedback; tap "Next" for a new round.
struct TutorialView: View {
    // Fixed tutorial board size
    private let boardSize: Int = 4
    private let cellSize: CGFloat = 40
    private let spacing: CGFloat = 2

    // Phases of the tutorial
    private enum Phase {
        case demo      // Auto animation
        case pause     // Show result briefly
        case practice  // User interaction
        case feedback  // Show correct/incorrect briefly
    }

    @State private var phase: Phase = .demo
    @State private var demoLeft: Int = 3 // how many auto demos before practice

    // Current target intersection
    @State private var targetRow: Int = 1
    @State private var targetCol: Int = 1

    // Animation controls (percent along the path: 0 → 1)
    @State private var icicleProgress: CGFloat = 0   // vertical (top → intersection row)
    @State private var flameProgress: CGFloat = 0    // horizontal (left → intersection col)

    // Practice selection
    @State private var userSelection: (row: Int, col: Int)? = nil
    @State private var wasCorrect: Bool = false

    // Timing
    @State private var isAnimating: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            header

            // Board area: headers + grid + animated overlays
            GeometryReader { geo in
                ZStack {
                    VStack(spacing: spacing) {
                        // Top header row (blank corner + 1..N + blank corner)
                        HStack(spacing: spacing) {
                            headerCorner()
                            ForEach(1...boardSize, id: \.self) { col in
                                headerLabel("\(col)")
                            }
                            headerCorner()
                        }

                        // Rows with left/right headers
                        ForEach(1...boardSize, id: \.self) { row in
                            HStack(spacing: spacing) {
                                headerLabel("\(row)")
                                ForEach(1...boardSize, id: \.self) { col in
                                    CellRect(
                                        row: row,
                                        col: col,
                                        size: cellSize,
                                        isHighlighted: isHighlighted(row: row, col: col)
                                    )
                                    .onTapGesture {
                                        handleTap(row: row, col: col)
                                    }
                                }
                                headerLabel("\(row)")
                            }
                        }

                        // Bottom header row
                        HStack(spacing: spacing) {
                            headerCorner()
                            ForEach(1...boardSize, id: \.self) { col in
                                headerLabel("\(col)")
                            }
                            headerCorner()
                        }
                    }
                    .frame(
                        width: gridPixelWidth,
                        height: gridPixelHeight
                    )

                    // Animated overlays (icicle + flame)
                    icicleOverlay
                    flameOverlay

                    // Intersection glow during demo/pause/feedback
                    if phase == .pause || phase == .feedback {
                        intersectionGlow
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: gridPixelHeight + 20)

            footerControls
        }
        .padding()
        .navigationTitle("Tutorial")
        .onAppear {
            startNewRound(isDemo: true)
        }
    }

    // MARK: - Layout helpers

    private var gridPixelWidth: CGFloat {
        // (board + 2 headers) * cell + gaps
        CGFloat(boardSize + 2) * cellSize + CGFloat(boardSize + 1 + 2) * spacing
    }

    private var gridPixelHeight: CGFloat {
        CGFloat(boardSize + 2) * cellSize + CGFloat(boardSize + 1 + 2) * spacing
    }

    private func headerLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .frame(width: cellSize, height: cellSize)
            .foregroundStyle(.primary)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func headerCorner() -> some View {
        Color.clear
            .frame(width: cellSize, height: cellSize)
    }

    // Grid cell (simple rounded square)
    private func CellRect(row: Int, col: Int, size: CGFloat, isHighlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(isHighlighted ? Color.yellow : Color.gray, lineWidth: isHighlighted ? 3 : 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
            )
            .frame(width: size, height: size)
    }

    private func isHighlighted(row: Int, col: Int) -> Bool {
        (row == targetRow || col == targetCol) && (phase == .pause || phase == .feedback)
    }

    // MARK: - Header / Footer

    private var header: some View {
        VStack(spacing: 4) {
            switch phase {
            case .demo:
                Text("Watch: rows meet columns at a cell")
                    .font(.headline)
                labelLine
            case .pause:
                Text("Intersection")
                    .font(.headline)
                resultLine
            case .practice:
                Text("Your turn: tap the intersection")
                    .font(.headline)
                labelLine
            case .feedback:
                Text(wasCorrect ? "Great!" : "Not quite – try the next one")
                    .font(.headline)
                resultLine
            }
        }
    }

    private var labelLine: some View {
        HStack(spacing: 12) {
            Text("Row: \(targetRow)")
                .foregroundStyle(.red)
            Text("Column: \(targetCol)")
                .foregroundStyle(.blue)
        }
        .font(.subheadline)
    }

    private var resultLine: some View {
        Text("\(targetRow) × \(targetCol) = \(targetRow * targetCol)")
            .font(.title3)
            .fontWeight(.semibold)
    }

    private var footerControls: some View {
        HStack {
            if phase == .practice || phase == .feedback {
                Button("Next") {
                    // Next practice round
                    startNewRound(isDemo: false)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Skip Demo") {
                    // Jump straight to practice
                    phase = .practice
                    demoLeft = 0
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Animated overlays

    private var icicleOverlay: some View {
        // Icicle falls from the top along the selected column
        // Draw only during demo
        Group {
            if phase == .demo {
                let x = columnCenterX(col: targetCol)
                let y = lerp(from: topHeaderBottomY, to: rowCenterY(row: targetRow), t: icicleProgress)
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .position(x: x, y: y)
                    .opacity(isAnimating ? 1 : 0)
            }
        }
    }

    private var flameOverlay: some View {
        // Flame moves from left along the selected row
        Group {
            if phase == .demo {
                let y = rowCenterY(row: targetRow)
                let x = lerp(from: leftHeaderRightX, to: columnCenterX(col: targetCol), t: flameProgress)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .position(x: x, y: y)
                    .opacity(isAnimating ? 1 : 0)
            }
        }
    }

    private var intersectionGlow: some View {
        let x = columnCenterX(col: targetCol)
        let y = rowCenterY(row: targetRow)
        return Circle()
            .fill(Color.yellow.opacity(0.35))
            .frame(width: cellSize * 0.9, height: cellSize * 0.9)
            .position(x: x, y: y)
            .overlay(
                Text("\(targetRow * targetCol)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 1.5)
            )
            .allowsHitTesting(false)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Coordinates helpers (centers/edges)

    private var gridTopY: CGFloat {
        // top header row (first row in VStack)
        0
    }

    private var topHeaderBottomY: CGFloat {
        // bottom edge of top header row's cells
        cellCenterY(forRowIndex: 0) + cellSize / 2
    }

    private var leftHeaderRightX: CGFloat {
        cellCenterX(forColIndex: 0) + cellSize / 2
    }

    private func rowCenterY(row: Int) -> CGFloat {
        // Row indexes in the VStack:
        // 0: top headers
        // 1..boardSize: grid rows
        // boardSize+1: bottom headers
        cellCenterY(forRowIndex: row)
    }

    private func columnCenterX(col: Int) -> CGFloat {
        // Column indexes in the HStack:
        // 0: left header
        // 1..boardSize: grid cols
        // boardSize+1: right header
        cellCenterX(forColIndex: col)
    }

    private func cellCenterY(forRowIndex idx: Int) -> CGFloat {
        // Sum heights of previous rows + this cell center
        let rowsBefore = CGFloat(idx) // number of rows above this one
        let gapsBefore = rowsBefore   // spacing gaps between those rows
        return (rowsBefore * cellSize) + (gapsBefore * spacing) + (cellSize / 2)
    }

    private func cellCenterX(forColIndex idx: Int) -> CGFloat {
        let colsBefore = CGFloat(idx)
        let gapsBefore = colsBefore
        return (colsBefore * cellSize) + (gapsBefore * spacing) + (cellSize / 2)
    }

    // MARK: - Flow control

    private func startNewRound(isDemo: Bool) {
        // Pick random target
        targetRow = Int.random(in: 1...boardSize)
        targetCol = Int.random(in: 1...boardSize)
        userSelection = nil
        wasCorrect = false

        if isDemo {
            phase = .demo
            runDemoAnimation()
        } else {
            phase = .practice
        }
    }

    private func runDemoAnimation() {
        isAnimating = true
        icicleProgress = 0
        flameProgress = 0

        // Animate icicle first, then flame to meet at the intersection.
        withAnimation(.easeInOut(duration: 0.9)) {
            icicleProgress = 1.0
        }

        // Chain the flame animation slightly after
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.9)) {
                flameProgress = 1.0
            }
        }

        // After animations complete, highlight and pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isAnimating = false
            phase = .pause

            // Hold the result briefly, then proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if demoLeft > 1 {
                    demoLeft -= 1
                    startNewRound(isDemo: true)
                } else {
                    // Switch to practice after the last demo
                    demoLeft = 0
                    phase = .practice
                }
            }
        }
    }

    private func handleTap(row: Int, col: Int) {
        guard phase == .practice else { return }
        userSelection = (row, col)
        wasCorrect = (row == targetRow && col == targetCol)
        phase = .feedback

        // Brief feedback, then stay in practice (Next → new round)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // do nothing; user uses "Next" to continue
        }
    }

    // MARK: - Math helpers
    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * min(max(t, 0), 1)
    }
}
