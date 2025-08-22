//
//  MemulApp.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 03/08/2025.
//

import SwiftUI

@main
struct MemulApp: App {
    init() {
        // Configure StoreKit on app launch and refresh entitlements
        IAPManager.shared.configureOnLaunch()
        Task { await IAPManager.shared.refreshEntitlements() }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.dark)   // force dark if you want
                .environment(\.colorScheme, .dark)
        }
    }
}
