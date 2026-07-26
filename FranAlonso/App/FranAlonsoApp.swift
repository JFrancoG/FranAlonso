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
    private let runtime: AppRuntime?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appDependencies, dependencies)
                .task(id: appDelegate.firebaseIsConfigured) {
                    runtime?.activateClientSync(
                        firebaseIsConfigured: appDelegate.firebaseIsConfigured
                    )
                }
        }
        .modelContainer(modelContainer)
    }
}

extension FranAlonsoApp {
    init() {
        do {
            let container = try ModelContainer.production(
                for: Schema.franAlonso
            )
            guard
                let environmentName = Bundle.main.object(
                    forInfoDictionaryKey: "AppEnvironment"
                ) as? String,
                let environment = FirestoreEnvironment(
                    rawValue: environmentName
                )
            else {
                fatalError("Unable to resolve the configured application environment")
            }
            let runtime = AppRuntime(
                modelContainer: container,
                environment: environment
            )
            modelContainer = container
            dependencies = runtime.dependencies
            self.runtime = runtime
        } catch {
            fatalError("Unable to create the production model container: \(error)")
        }
    }

    init(composing modelContainer: ModelContainer, dependencies: AppDependencies) {
        self.modelContainer = modelContainer
        self.dependencies = dependencies
        runtime = nil
    }
}
