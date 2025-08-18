//
//  StartView.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 02/08/2025.
//

import SwiftUI

struct StartView: View {
    @State private var settings = GameSettings(
        boardSize: 5,
        players: [
            Player(name: "Player 1", color: .red),
            Player(name: "Player 2", color: .blue)
        ]
    )

    @State private var isActive = false
    @State private var gameViewModel: GameViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background: soft gradient wash
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.10),
                        Color.purple.opacity(0.10),
                        Color.teal.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // Hero
                        VStack(spacing: 10) {
                            StartIllustrationView()
                                .frame(width: 120, height: 120)
                                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)

                            Text(NSLocalizedString("app_title", comment: "App title on start screen"))
                                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center)

                            Text(NSLocalizedString("start_tagline", comment: "Short tagline under app title on the start screen"))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 12)

                        // Start Game — primary CTA
                        VStack(spacing: 12) {
                            Button {
                                startGame()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                    Text(NSLocalizedString("start_game", comment: "Start game button"))
                                        .fontWeight(.semibold)
                                }
                                .font(.title3)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .blue.opacity(0.2), radius: 10, y: 4)

                            // Quick status chips
                            HStack(spacing: 8) {
                                Label(
                                    String(
                                        format: NSLocalizedString("board_size_value", comment: "Size: %d × %d"),
                                        settings.boardSize, settings.boardSize
                                    ),
                                    systemImage: "square.grid.3x3"
                                )
                                .font(.footnote)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())

                                Label(text(for: settings.difficulty), systemImage: "bolt.badge.a")
                                    .font(.footnote)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        // Quick Practice
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: NSLocalizedString("quick_practice", comment: ""))
                            VStack(spacing: 12) {
                                // Quick Multiplication (NavigationLink card)
                                StartNavCard(
                                    title: NSLocalizedString("quick_multiply", comment: ""),
                                    subtitle: String(
                                        format: NSLocalizedString("range_multiplication", comment: ""),
                                        settings.multiplicationMin, settings.multiplicationMax
                                    ),
                                    systemImage: "x.squareroot",
                                    tint: .indigo
                                ) {
                                    QuickPracticeView(
                                        mode: .multiplication,
                                        minValue: settings.multiplicationMin,
                                        maxValue: settings.multiplicationMax,
                                        difficulty: settings.difficulty
                                    )
                                    .navigationTitle(NSLocalizedString("quick_multiply", comment: ""))
                                }

                                if settings.isDivisionUnlocked {
                                    StartNavCard(
                                        title: NSLocalizedString("quick_divide", comment: ""),
                                        subtitle: String(
                                            format: NSLocalizedString("range_division", comment: ""),
                                            settings.divisionMin, settings.divisionMax
                                        ),
                                        systemImage: "divide",
                                        tint: .teal
                                    ) {
                                        QuickPracticeView(
                                            mode: .division,
                                            minValue: settings.divisionMin,
                                            maxValue: settings.divisionMax,
                                            difficulty: settings.difficulty
                                        )
                                        .navigationTitle(NSLocalizedString("quick_divide", comment: ""))
                                    }
                                } else {
                                    // Locked (non-navigating) card
                                    StartInfoCard(
                                        title: NSLocalizedString("quick_divide_locked", comment: ""),
                                        subtitle: NSLocalizedString("division_premium_hint", comment: ""),
                                        systemImage: "lock.fill",
                                        tint: .gray.opacity(0.6),
                                        locked: true
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Learn & Explore
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: NSLocalizedString("tutorial", comment: ""))
                            StartNavCard(
                                title: NSLocalizedString("tutorial", comment: ""),
                                subtitle: NSLocalizedString("tutorial_intersect_sub", comment: ""),
                                systemImage: "questionmark.circle.fill",
                                tint: .orange
                            ) {
                                TutorialView()
                                    .navigationTitle(NSLocalizedString("tutorial_title", comment: ""))
                            }
                        }
                        .padding(.horizontal)

                        // Settings, About & Achievements
                        HStack(spacing: 12) {
                            NavigationLink {
                                SettingsView(settings: $settings)
                                    .navigationTitle(NSLocalizedString("settings_title", comment: ""))
                            } label: {
                                SmallPillButton(title: NSLocalizedString("settings", comment: ""), systemImage: "gearshape.fill")
                            }

                            NavigationLink {
                                AboutView()
                                    .navigationTitle(NSLocalizedString("ab_navigation_title", comment: ""))
                            } label: {
                                SmallPillButton(title: NSLocalizedString("about", comment: ""), systemImage: "info.circle.fill")
                            }

                            // Achievements entry (new)
                            NavigationLink {
                                AchievementsView()
                                    .navigationTitle(NSLocalizedString("achievements_title", comment: "Achievements"))
                            } label: {
                                SmallPillButton(title: NSLocalizedString("achievements", comment: "Achievements"), systemImage: "star.fill")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 8)
                }
            }
            // Programmatic destination for Start Game
            .navigationDestination(isPresented: $isActive) {
                if let gameViewModel = gameViewModel {
                    GameView(viewModel: gameViewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helpers

    private func text(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:   return NSLocalizedString("difficulty_easy", comment: "")
        case .normal: return NSLocalizedString("difficulty_normal", comment: "")
        case .hard:   return NSLocalizedString("difficulty_hard", comment: "")
        }
    }

    /// Starts a new game on the main actor
    @MainActor
    private func startGame() {
        gameViewModel = GameViewModel(settings: settings)
        isActive = true
    }
}

#Preview {
    NavigationStack { StartView() }
}

// MARK: - Components

/// Slim section title with material-aware styling
private struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

/// Navigation card — the whole card is a NavigationLink
private struct StartNavCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.quaternary)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// Informational (non-navigating) card, supports "locked" look
private struct StartInfoCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var locked: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .opacity(locked ? 0.65 : 1)
    }
}

/// Compact pill-style buttons for Settings / About / Achievements
private struct SmallPillButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// Decorative vector illustration for the hero area
private struct StartIllustrationView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cell = size / 5.5

            ZStack {
                // Soft circular plate
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1)

                // Grid 3x3
                let gridOffset = size * 0.18
                let start = -size/2 + gridOffset
                let rows = 3, cols = 3

                // Board cells
                ForEach(0..<rows, id: \.self) { r in
                    ForEach(0..<cols, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.blue.opacity(0.25), lineWidth: 1)
                            )
                            .frame(width: cell, height: cell)
                            .position(
                                x: size/2 + start + CGFloat(c) * (cell + 6),
                                y: size/2 + start + CGFloat(r) * (cell + 6)
                            )
                    }
                }

                // Highlight row & column
                let rSel = 1, cSel = 2
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.35))
                    .frame(width: cell * 3 + 12, height: cell)
                    .position(x: size/2 + start + (cell + 6), y: size/2 + start + CGFloat(rSel) * (cell + 6))
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.35))
                    .frame(width: cell, height: cell * 3 + 12)
                    .position(x: size/2 + start + CGFloat(cSel) * (cell + 6), y: size/2 + start + (cell + 6))

                // Crossing target
                Text("🎯")
                    .font(.system(size: cell * 0.9))
                    .position(
                        x: size/2 + start + CGFloat(cSel) * (cell + 6),
                        y: size/2 + start + CGFloat(rSel) * (cell + 6)
                    )

                // Puzzle piece corner
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.25))
                    .frame(width: cell * 1.2, height: cell * 1.2)
                    .rotationEffect(.degrees(-10))
                    .offset(x: size * 0.18, y: -size * 0.18)

                // Magnifying glass
                Group {
                    Circle()
                        .stroke(Color.black.opacity(0.15), lineWidth: 3)
                        .background(Circle().fill(.white.opacity(0.7)))
                        .frame(width: cell * 1.2, height: cell * 1.2)
                        .offset(x: -size * 0.18, y: size * 0.12)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: cell * 0.9, height: 5)
                        .rotationEffect(.degrees(35))
                        .offset(x: -size * 0.02, y: size * 0.26)
                }
            }
            .padding(6)
            .frame(width: size, height: size)
        }
    }
}
