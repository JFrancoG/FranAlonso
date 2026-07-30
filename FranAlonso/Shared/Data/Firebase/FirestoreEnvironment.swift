/// Selects the approved Firestore namespace without defaulting to a live environment.
enum FirestoreEnvironment: String {
    case develop
    case production
}

/// Identifies Firestore business collections that have concrete Data adapters.
enum FirestoreCollection: String {
    case clients
    case products
    case services
}

extension FirestoreEnvironment {
    /// Returns the business collection path rooted in this explicit environment.
    func collectionPath(for collection: FirestoreCollection) -> String {
        "\(rawValue)/collections/\(collection.rawValue)"
    }

    /// Returns the change-sequence counter document path for one business collection.
    func syncMetadataDocumentPath(
        for collection: FirestoreCollection
    ) -> String {
        "\(rawValue)/collections/syncMetadata/\(collection.rawValue)"
    }
}
