//
//  FranAlonsoApp.swift
//  FranAlonso
//
//  Created by Jesús Franco on 11.06.2026.
//

import SwiftUI

@main
@MainActor
struct FranAlonsoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appDependencies, dependencies)
        }
    }
}
