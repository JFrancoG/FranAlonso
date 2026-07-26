/// Errors raised when a Product payload cannot represent a Domain value.
enum ProductMappingError: Error, Equatable {
    case invalidIdentifier(String)
    case invalidPersistedStatus(String)
}
