//
//  FranAlonsoApp.swift
//  FranAlonso
//
//  Created by Jesús Franco on 11.06.2026.
//

import SwiftData
import SwiftUI

@main
struct FranAlonsoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appDependencies, dependencies)
        }
        .modelContainer(modelContainer)
    }
}

extension FranAlonsoApp {
    init() {
        dependencies = .live()

        do {
            modelContainer = try ModelContainer.production(
                for: Schema.franAlonso
            )
        } catch {
            fatalError("Unable to create the production model container: \(error)")
        }
    }

    init(composing modelContainer: ModelContainer, dependencies: AppDependencies) {
        self.modelContainer = modelContainer
        self.dependencies = dependencies
    }

}
