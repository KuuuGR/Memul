//
//  SplashView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0.0
    @State private var glowRadius: CGFloat = 0

    // Previously 4.0s → 60% = 2.4s
    private let totalDelay: TimeInterval = 2.4

    private var gloss: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .white.opacity(0.22),
                .white.opacity(0.08),
                .clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.1)
                .ignoresSafeArea()

            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.6)
                .clipShape(Circle())
                .overlay(Circle().fill(gloss))
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .shadow(color: .white.opacity(0.28), radius: glowRadius)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        .scaleEffect(logoScale * 1.06)
                )
                .onAppear {
                    // Reset
                    logoOpacity = 0.0
                    logoScale = 0.85
                    glowRadius = 0

                    // Durations scaled to 60% of previous
                    withAnimation(.easeInOut(duration: 0.72)) {   // 1.2 → 0.72
                        logoOpacity = 0.25
                    }
                    withAnimation(.easeOut(duration: 0.84).delay(0.18)) { // 1.4 → 0.84, delay 0.3 → 0.18
                        logoScale = 1.0
                        glowRadius = 16
                    }
                    withAnimation(.easeIn(duration: 0.48).delay(1.14)) { // 0.8 → 0.48, delay 1.9 → 1.14
                        logoOpacity = 0.85
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        withAnimation(.easeOut(duration: 0.24)) { // 0.4 → 0.24
                            isActive = true
                        }
                    }
                }
        }
        .fullScreenCover(isPresented: $isActive) {
            StartView()
                .preferredColorScheme(.dark)
                .environment(\.colorScheme, .dark)
        }
    }
}
