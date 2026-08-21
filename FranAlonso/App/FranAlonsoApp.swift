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
#if FRANALONSO_AUTH_FIXTURE
    private let authenticationRootViewModel: AuthenticationRootViewModel?
#endif

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
            bootstrapFailure
#if FRANALONSO_AUTH_FIXTURE
        case .fixtureConfigurationFailed:
            bootstrapFailure
#endif
        case .configured:
            if let authenticationRootViewModel = runtime?.authenticationRootViewModel {
                AuthenticationRootScreen(viewModel: authenticationRootViewModel)
            } else {
                ProgressView {
                    Text(.authenticationBootstrapPreparing)
                }
            }
#if FRANALONSO_AUTH_FIXTURE
        case .fixtureReady:
            if let authenticationRootViewModel {
                AuthenticationRootScreen(viewModel: authenticationRootViewModel)
            } else {
                ProgressView {
                    Text(.authenticationBootstrapPreparing)
                }
            }
#endif
        }
    }

    var bootstrapFailure: some View {
        ContentUnavailableView {
            Label {
                Text(.authenticationBootstrapFailedTitle)
            } icon: {
                Image(systemName: "exclamationmark.icloud.fill")
            }
        } description: {
            Text(.authenticationBootstrapFailedMessage)
        }
    }
}

extension FranAlonsoApp {
    init() {
        do {
            let composition = try ApplicationComposition.make(
                plan: ApplicationLaunchPlan.current
            )
            modelContainer = composition.modelContainer
            dependencies = composition.dependencies
            runtime = composition.runtime
#if FRANALONSO_AUTH_FIXTURE
            authenticationRootViewModel = composition.authenticationRootViewModel
#endif
        } catch {
            fatalError("Unable to compose the application: \(error)")
        }
    }

    init(composing modelContainer: ModelContainer, dependencies: AppDependencies) {
        self.modelContainer = modelContainer
        self.dependencies = dependencies
        runtime = nil
#if FRANALONSO_AUTH_FIXTURE
        authenticationRootViewModel = nil
#endif
    }
}
