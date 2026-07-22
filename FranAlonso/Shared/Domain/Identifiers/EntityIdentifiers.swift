import Foundation

struct ClientID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

struct ProductID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

struct ServiceID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

struct SaleID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

struct SaleLineID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

struct BillingDocumentID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}

struct AppointmentID: RawRepresentable, Codable, Hashable {
    let rawValue: UUID
}
