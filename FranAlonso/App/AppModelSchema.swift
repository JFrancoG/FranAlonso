import SwiftData

extension Schema {
    /// The complete SwiftData schema currently owned by Fran Alonso.
    static var franAlonso: Schema {
        Schema(versionedSchema: PhaseFiveBaselineSchema.self)
    }
}
