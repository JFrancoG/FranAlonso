import Foundation
import SwiftData
import Testing
@testable import FranAlonso

struct SaleGlobalDiscountDataFixture {
    static let saleID = UUID(uuidString: "92000000-0000-0000-0000-000000000001")!
    static let operationA = UUID(uuidString: "92000000-0000-0000-0000-000000000002")!
    static let operationB = UUID(uuidString: "92000000-0000-0000-0000-000000000003")!
    static let remoteOperation = UUID(uuidString: "92000000-0000-0000-0000-000000000004")!
    static let conflictSaleID = UUID(uuidString: "92000000-0000-0000-0000-000000000090")!

    // These bytes describe the published v1 contract; no production writer constructs them.
    static let linesV1 = #"[{"discount":{"percentage":"10"},"id":"92000000-0000-0000-0000-000000000010","quantity":1,"serviceID":"92000000-0000-0000-0000-000000000011","serviceName":"Historical promotion","status":"upcoming","taxRate":{"percentage":"21"},"unitPrice":{"amount":"100","currency":"EUR"}}]"#
    static let saleV1 = #"{"createdAt":"3ff0000000000000","id":"92000000-0000-0000-0000-000000000001","lines":[{"discount":{"percentage":"10"},"id":"92000000-0000-0000-0000-000000000010","quantity":1,"serviceID":"92000000-0000-0000-0000-000000000011","serviceName":"Historical promotion","status":"upcoming","taxRate":{"percentage":"21"},"unitPrice":{"amount":"100","currency":"EUR"}}],"payloadVersion":1,"status":{"kind":"draft"}}"#
    static let global20 = #"{"percentage":"20","policy":"lineThenGlobalV1"}"#

    static var saleV2: String { salePayload(version: 2, global: global20) }
    static var legacyBaseV1: Data { Data(#"{"legacy":{"_0":\#(saleV1)}}"#.utf8) }
    static var remoteV1: Data {
        Data(#"{"content":{"live":{"_0":\#(saleV1)}},"version":{"legacy":{}}}"#.utf8)
    }

    static func salePayload(version: Int, global: String?) -> String {
        let extra = global.map { #", "globalDiscount":\#($0)"# } ?? ""
        return #"{"payloadVersion":\#(version),"id":"\#(saleID.uuidString)","createdAt":"3ff0000000000000","lines":\#(linesV1),"status":{"kind":"draft"}\#(extra)}"#
    }

    static func domain(globalPercentage: Decimal? = nil) throws -> Sale {
        let historical = try JSONDecoder().decode(SaleDTO.self, from: Data(saleV1.utf8)).toDomain()
        let global = try globalPercentage.map {
            SaleGlobalDiscount(discount: try Discount(percentage: $0), policy: .lineThenGlobalV1)
        }
        return try Sale.draft(
            id: historical.id,
            clientID: historical.clientID,
            createdAt: historical.createdAt,
            lines: historical.lines,
            globalDiscount: global
        )
    }

    static func rawModel(version: Int = 1, bytes: Data = Data(linesV1.utf8)) -> SaleModel {
        SaleModel(
            id: saleID,
            clientID: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 1),
            createdAtCanonical: "3ff0000000000000",
            statusKindRawValue: "draft",
            paymentID: nil,
            paymentMethodRawValue: nil,
            paidAtCanonical: nil,
            documentID: nil,
            closedAtCanonical: nil,
            reversalID: nil,
            voidedAtCanonical: nil,
            linesPayloadVersion: version,
            linesData: bytes
        )
    }

    static func memoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "GlobalDiscountTests",
            schema: .franAlonso,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: Schema.franAlonso, configurations: [configuration])
    }

    static func fileContainer(at url: URL, raw: Bool = false) throws -> ModelContainer {
        let schema = raw ? Schema(StockMovementsSchema.models, version: Schema.Version(3, 0, 0)) : .franAlonso
        let configuration = ModelConfiguration(
            "GlobalDiscountSchema3",
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        if raw {
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: PhaseFiveSchemaMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func withStore(_ operation: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-GlobalDiscount-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try operation(directory.appending(path: "HistoricalSchema3.store"))
    }
}
