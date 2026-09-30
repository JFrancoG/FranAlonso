extension AppDependencies {
    /// Creates an independent selection session over the application's shared local service catalogue.
    @MainActor
    func makeServicePicker() -> ServicePickerViewModel {
        ServicePickerViewModel(observeServices: observeServices)
    }
}
