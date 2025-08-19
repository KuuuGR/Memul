//
//  MemulApp.swift
//  Memul
//
//  Created by Grzegorz Kulesza on 03/08/2025.
//

import SwiftUI

@main
struct MemulApp: App {
    // Keep a reference so SwiftUI observes IAP changes (optional but handy)
    @StateObject private var iap = IAPManager.shared

    init() {
        // Configure StoreKit on app launch
        IAPManager.shared.configureOnLaunch()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .preferredColorScheme(.dark)   // force dark if you want
                .environment(\.colorScheme, .dark)
        }
    }
}
