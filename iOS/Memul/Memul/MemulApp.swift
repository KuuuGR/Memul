//
//  MemulApp.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 03/08/2025.
//

import SwiftUI

@main
struct MemulApp: App {
    @Environment(\.colorScheme) var colorScheme

    var body: some Scene {
        WindowGroup {
            // Show animated splash first, like in your TimeToSkill app
            SplashView()
                .preferredColorScheme(.dark)           // Force dark during splash (and app if you want)
                .environment(\.colorScheme, .dark)     // Apply to all views
        }
    }
}
