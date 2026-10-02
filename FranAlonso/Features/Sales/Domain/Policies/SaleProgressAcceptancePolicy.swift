/// Accepts work against an unchanged snapshot or recognizes its exact replay without downgrading later progress.
struct SaleProgressAcceptancePolicy {
    /// Comparison protects all captured terms; checks and commit belong to the repository's owning context.
    /// - Throws: `SaleProgressError.staleSale` or aggregate/line validation errors.
    func callAsFunction(expected: Sale, current: Sale, action: SaleProgressAction) throws -> Sale {
        let candidate = try action.applying(to: expected)
        guard current == expected || current == candidate else { throw SaleProgressError.staleSale }
        return candidate
    }
}
