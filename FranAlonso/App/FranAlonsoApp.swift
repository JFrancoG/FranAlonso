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
            applicationRoot
                .environment(\.appDependencies, dependencies)
                .task(id: appDelegate.firebaseBootstrapState) {
                    let firebaseIsConfigured = appDelegate.firebaseBootstrapState == .configured
                    runtime?.activateAuthentication(
                        firebaseIsConfigured: firebaseIsConfigured
                    )
                    runtime?.activateClientSync(
                        firebaseIsConfigured: firebaseIsConfigured
                    )
                    runtime?.activateProductSync(
                        firebaseIsConfigured: firebaseIsConfigured
                    )
                    runtime?.activateServiceSync(
                        firebaseIsConfigured: firebaseIsConfigured
                    )
                    runtime?.activateSaleSync(
                        firebaseIsConfigured: firebaseIsConfigured
                    )
                }
        }
        .modelContainer(modelContainer)
    }
}

private extension FranAlonsoApp {
    @ViewBuilder
    var applicationRoot: some View {
        switch appDelegate.firebaseBootstrapState {
        case .pending:
            ProgressView {
                Text(.authenticationBootstrapPreparing)
            }
        case .failed:
            ContentUnavailableView {
                Label {
                    Text(.authenticationBootstrapFailedTitle)
                } icon: {
                    Image(systemName: "exclamationmark.icloud.fill")
                }
            } description: {
                Text(.authenticationBootstrapFailedMessage)
            }
        case .configured:
            if let authenticationRootViewModel = runtime?.authenticationRootViewModel {
                AuthenticationRootScreen(viewModel: authenticationRootViewModel)
            } else {
                ProgressView {
                    Text(.authenticationBootstrapPreparing)
                }
            }
        }
    }
}

extension FranAlonsoApp {
    init() {
        do {
            let container = try ModelContainer.production(
                for: Schema.franAlonso,
                migrationPlan: PhaseFiveSchemaMigrationPlan.self
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
