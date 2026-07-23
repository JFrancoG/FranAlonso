import Foundation

/// A type-safe, stable identifier for a client.
struct ClientID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A type-safe, stable identifier for a physical inventory product.
struct ProductID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A type-safe, stable identifier for a commercial service.
struct ServiceID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A type-safe, stable identifier for a sale aggregate.
struct SaleID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A type-safe, stable identifier for a historical line snapshot within a sale.
struct SaleLineID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A stable operation identifier used to make payment registration idempotent.
struct PaymentID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A stable operation identifier used to make compensating sale reversals idempotent.
struct SaleReversalID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A type-safe, stable identifier for a billing document.
struct BillingDocumentID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

/// A type-safe, stable identifier for an appointment.
struct AppointmentID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}
