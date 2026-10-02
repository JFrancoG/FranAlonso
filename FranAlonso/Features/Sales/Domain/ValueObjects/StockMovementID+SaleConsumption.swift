import CryptoKit
import Foundation

extension StockMovementID {
    /// Stable UUIDv8 for one original sale-line consumption, independent of payment attempts and display order.
    /// Hashes UTF-8 "FranAlonso.sale-stock.v1", NUL, lowercase sale UUID, NUL, lowercase line UUID with SHA256.
    /// The first 16 digest bytes retain 122 bits after setting version 8 and RFC variant 10.
    /// This published namespace/layout must never change for existing events; payload equality detects collisions.
    static func saleConsumption(saleID: SaleID, lineID: SaleLineID) -> StockMovementID {
        let name = "FranAlonso.sale-stock.v1\0\(saleID.rawValue.uuidString.lowercased())" +
            "\0\(lineID.rawValue.uuidString.lowercased())"
        var bytes = Array(SHA256.hash(data: Data(name.utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0f) | 0x80
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        let identifier = UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
        return StockMovementID(rawValue: identifier)
    }
}
