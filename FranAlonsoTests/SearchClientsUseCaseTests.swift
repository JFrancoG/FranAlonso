import Foundation
import Testing
@testable import FranAlonso

@Suite("Search clients use case")
struct SearchClientsUseCaseTests {
    @Test(
        arguments: [
            ("", [3, 1, 2]),
            (" \n\t ", [3, 1, 2]),
            ("ZOE", [3]),
            ("alvarez", [3, 1]),
            ("  ÁLVAREZ \n", [3, 1]),
            ("TEST-002", [2]),
            ("test-", [1, 2]),
            ("missing", [])
        ]
    )
    func `search matches local names or tax identifiers and preserves snapshot order`(
        query: String,
        expectedIDs: [Int]
    ) {
        let clients = [
            Client.draft(id: searchClientID(3), displayName: "Zoé Álvarez"),
            Client(
                id: searchClientID(1),
                displayName: "Ángela Álvarez",
                taxIdentifier: "TEST-001",
                billingAddress: nil,
                status: .consentPendingUpload
            ),
            Client(
                id: searchClientID(2),
                displayName: "Bruno Ejemplo",
                taxIdentifier: "TEST-002",
                billingAddress: nil,
                status: .draft
            )
        ]

        let matches = SearchClientsUseCase()(clients, query: query)

        #expect(matches.map(\.id) == expectedIDs.map(searchClientID))
    }

    @Test(arguments: ["", "Álvarez", "TEST-001"])
    func `an empty local snapshot remains empty`(_ query: String) {
        #expect(SearchClientsUseCase()([], query: query).isEmpty)
    }
}

private func searchClientID(_ suffix: Int) -> ClientID {
    ClientID(rawValue: UUID(uuidString: "08010001-0000-0000-0000-00000000000\(suffix)")!)
}
