import Foundation

/// Replaceable document capabilities for one authorized form session.
struct ClientConsentServices {
    let repository: any ClientDocumentRepository
    let catalog: any ClientDocumentCatalog
    let renderer: any ClientDocumentRenderer
    let storage: any ClientDocumentStorage
    let version: String
    let language: String
    let now: @Sendable () -> Date
    let newID: @Sendable () -> UUID
}
