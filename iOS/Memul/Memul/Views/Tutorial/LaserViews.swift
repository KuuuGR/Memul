//
//  LaserViews.swift
//  Memul
//
//  Row = RED (horizontal), Column = BLUE (vertical).
//

import SwiftUI

struct LaserHorizontal: View {
    // ROW laser — RED
    let y: CGFloat
    let fromX: CGFloat
    let toX: CGFloat

    var body: some View {
        let width = max(0, toX - fromX)
        RoundedRectangle(cornerRadius: 3)
            .fill(LinearGradient(
                colors: [.red.opacity(0.1), .red, .white, .red, .red.opacity(0.1)],
                startPoint: .leading, endPoint: .trailing
            ))
            .frame(width: width, height: 6)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.7), lineWidth: 0.5))
            .position(x: fromX + width / 2, y: y)
            .shadow(color: .red.opacity(0.6), radius: 4)
            .allowsHitTesting(false)
    }
}

struct LaserVertical: View {
    // COLUMN laser — BLUE
    let x: CGFloat
    let fromY: CGFloat
    let toY: CGFloat

    var body: some View {
        let height = max(0, toY - fromY)
        RoundedRectangle(cornerRadius: 3)
            .fill(LinearGradient(
                colors: [.blue.opacity(0.1), .blue, .white, .blue, .blue.opacity(0.1)],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: 6, height: height)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.7), lineWidth: 0.5))
            .position(x: x, y: fromY + height / 2)
            .shadow(color: .blue.opacity(0.6), radius: 4)
            .allowsHitTesting(false)
    }
}
