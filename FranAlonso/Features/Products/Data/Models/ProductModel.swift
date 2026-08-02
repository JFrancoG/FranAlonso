import Foundation
import SwiftData

/// The local SwiftData representation of Product catalog metadata.
///
/// Domain values are mapped at the Data boundary so live persistent models never
/// leave the context that owns them.
@Model
final class ProductModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var statusRawValue: String

    init(id: UUID, name: String, statusRawValue: String) {
        self.id = id
        self.name = name
        self.statusRawValue = statusRawValue
    }
}
