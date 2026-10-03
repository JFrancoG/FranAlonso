import Foundation
import ImageIO
import UniformTypeIdentifiers

struct BillingSignatureImageValidator {
    static let maximumByteCount = 2_097_152

    /// Validates dimensions before decoding; header recognition alone does not accept an image.
    static func validate(_ data: Data) throws {
        let readingOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let decodingOptions = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard !data.isEmpty, data.count <= maximumByteCount,
              let source = CGImageSourceCreateWithData(data as CFData, readingOptions),
              let type = CGImageSourceGetType(source),
              [UTType.png.identifier, UTType.jpeg.identifier].contains(type as String),
              CGImageSourceGetCount(source) == 1, CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              (1...4096).contains(width), (1...4096).contains(height), width * height <= 4_194_304,
              let image = CGImageSourceCreateImageAtIndex(source, 0, decodingOptions),
              image.width == width, image.height == height else {
            throw BillingAssetError.invalidSignature
        }
    }
}
