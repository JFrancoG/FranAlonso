import CryptoKit
import Foundation

extension StockMovementID {
    /// Stable UUIDv8 for the only compensation of one original sale-line consumption.
    /// Hashes UTF-8 "FranAlonso.sale-stock-reversal.v1", NUL, lowercase sale UUID, NUL, lowercase line UUID.
    /// SHA256's first 16 bytes retain 122 bits after version 8 and RFC variant 10.
    /// Reversal identity belongs to the conflict payload, so concurrent reversals cannot create two additive inverses.
    static func saleReversal(saleID: SaleID, lineID: SaleLineID) -> StockMovementID {
        let name = "FranAlonso.sale-stock-reversal.v1\0\(saleID.rawValue.uuidString.lowercased())" +
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
