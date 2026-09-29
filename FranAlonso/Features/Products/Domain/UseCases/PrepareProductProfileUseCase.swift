/// Converts editable product text into a validated metadata-only command input.
struct PrepareProductProfileUseCase {
    /// Rejects a blank name without changing identity, availability or inventory.
    func callAsFunction(name: String) throws -> ProductProfile {
        try ProductProfile(name: name)
    }
}
