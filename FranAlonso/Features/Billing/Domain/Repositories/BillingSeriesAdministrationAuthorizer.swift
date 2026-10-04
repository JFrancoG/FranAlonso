/// Fresh administrative authority for one explicit billing-sequence command.
///
/// Implementations fail closed unless the principal currently holds administrative authority
/// for this operation. Login, a local-store binding and caller-provided flags are insufficient.
/// Returning an opaque identity creates no role and proves no enforcement at a remote backend.
/// Callers revalidate after suspension and require the same principal before publishing acceptance.
protocol BillingSeriesAdministrationAuthorizer: Sendable {
    func authorize(_ request: BillingSeriesAdjustmentRequest) async throws -> String
}
