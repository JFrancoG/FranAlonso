import SwiftUI

private let defaultAppDependencies = AppDependencies.preview()

extension EnvironmentValues {
    @Entry var appDependencies = defaultAppDependencies
}
