/// Selects the approved Firestore namespace without defaulting to a live environment.
enum FirestoreEnvironment: String {
    case develop
    case production
}
