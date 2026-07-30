import Foundation

/// Errors raised when a Service payload cannot represent the same valid Domain snapshot.
enum ServiceMappingError: Error, Equatable {
    /// The Service transport identifier is not a UUID.
    case invalidIdentifier(String)

    /// The linked Product transport identifier is not a UUID.
    case invalidLinkedProductIdentifier(String)

    /// Domain minor-unit normalization would change the remotely supplied amount.
    case moneyNormalizationChanged(original: Decimal, normalized: Decimal)

    /// A persisted Service type no longer maps to a supported transport value.
    case invalidPersistedType(String)

    /// A persisted currency no longer maps to a supported transport value.
    case invalidPersistedCurrency(String)

    /// A persisted Service status no longer maps to a supported transport value.
    case invalidPersistedStatus(String)

    /// A persisted decimal string is malformed or is not canonical.
    case invalidPersistedDecimal(String)
}
