import Foundation

struct BillingAssetFileReader {
    /// Reads at most one byte beyond the limit, including when the file grows during the read.
    static func read(_ url: URL, maximumByteCount: Int) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }
        var data = Data()
        while data.count <= maximumByteCount {
            let remaining = maximumByteCount + 1 - data.count
            guard let chunk = try handle.read(upToCount: remaining), !chunk.isEmpty else { break }
            data.append(chunk)
        }
        return data
    }
}
