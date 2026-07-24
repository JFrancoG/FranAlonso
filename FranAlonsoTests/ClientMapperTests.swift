import Foundation
import Testing
@testable import FranAlonso

@Suite("Client DTO and mapper")
struct ClientMapperTests {
    @Test("Decodes a complete active client fixture")
    func decodesACompleteActiveClientFixture() throws {
        let dto = try decodeClientDTO(
            Data(
                #"""
                {
                  "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                  "displayName": "Ana Alonso",
                  "taxIdentifier": "12345678Z",
                  "billingAddress": {
                    "streetLine": "Calle Bailén, 33",
                    "postalCode": "41001",
                    "city": "Sevilla",
                    "province": "Sevilla"
                  },
                  "status": "active",
                  "consentReference": "consents/ana-alonso/signed.pdf"
                }
                """#.utf8
            )
        )

        #expect(dto == completeClientDTO())
    }

    @Test("Preserves the missing nested field context")
    func preservesTheMissingNestedFieldContext() {
        let data = Data(
            #"""
            {
              "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
              "displayName": "Ana Alonso",
              "billingAddress": {
                "streetLine": "Calle Bailén, 33",
                "city": "Sevilla",
                "province": "Sevilla"
              },
              "status": "draft"
            }
            """#.utf8
        )

        do {
            _ = try decodeClientDTO(data)
            Issue.record("Expected a missing postalCode decoding error")
        } catch DecodingError.keyNotFound(let key, let context) {
            #expect(key.stringValue == "postalCode")
            #expect(context.codingPath.map(\.stringValue) == ["billingAddress"])
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }
    }

    @Test("Preserves the corrupt nested field context")
    func preservesTheCorruptNestedFieldContext() {
        let data = Data(
            #"""
            {
              "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
              "displayName": "Ana Alonso",
              "billingAddress": {
                "streetLine": "Calle Bailén, 33",
                "postalCode": 41001,
                "city": "Sevilla",
                "province": "Sevilla"
              },
              "status": "draft"
            }
            """#.utf8
        )

        do {
            _ = try decodeClientDTO(data)
            Issue.record("Expected a postalCode type mismatch")
        } catch DecodingError.typeMismatch(_, let context) {
            #expect(
                context.codingPath.map(\.stringValue) == [
                    "billingAddress",
                    "postalCode"
                ]
            )
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }
    }

    @Test("Preserves the unknown status field context")
    func preservesTheUnknownStatusFieldContext() {
        let data = Data(
            #"""
            {
              "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
              "displayName": "Ana Alonso",
              "status": "suspended"
            }
            """#.utf8
        )

        do {
            _ = try decodeClientDTO(data)
            Issue.record("Expected an unknown status decoding error")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["status"])
        } catch {
            Issue.record("Unexpected decoding error: \(error)")
        }
    }

    @Test("Preserves a client DTO through JSON")
    func preservesAClientDTOThroughJSON() throws {
        let dto = completeClientDTO()

        let decodedDTO = try decodeClientDTO(JSONEncoder().encode(dto))

        #expect(decodedDTO == dto)
    }

    @Test("Maps every client activation state through the DTO boundary")
    func mapsEveryClientActivationStateThroughTheDTOBoundary() throws {
        let clients = [
            Client.draft(
                id: try clientID("10000000-0000-0000-0000-000000000001"),
                displayName: "Draft client"
            ),
            Client(
                id: try clientID("10000000-0000-0000-0000-000000000002"),
                displayName: "Pending client",
                taxIdentifier: nil,
                billingAddress: nil,
                status: .consentPendingUpload
            ),
            Client(
                id: try clientID("10000000-0000-0000-0000-000000000003"),
                displayName: "Active client",
                taxIdentifier: "12345678Z",
                billingAddress: BillingAddress(
                    streetLine: "Calle Bailén, 33",
                    postalCode: "41001",
                    city: "Sevilla",
                    province: "Sevilla"
                ),
                status: .active(
                    consentReference: try ClientConsentReference(
                        rawValue: "consents/active/signed.pdf"
                    )
                )
            )
        ]

        for client in clients {
            let dto = ClientMapper.dto(from: client)
            let mappedClient = try ClientMapper.domain(from: dto)

            #expect(mappedClient == client)
        }
    }

    @Test("Rejects an invalid client identifier")
    func rejectsAnInvalidClientIdentifier() {
        let dto = completeClientDTO(id: "not-a-uuid")

        #expect(throws: ClientMapperError.invalidIdentifier("not-a-uuid")) {
            try ClientMapper.domain(from: dto)
        }
    }

    @Test("Rejects active clients without valid consent")
    func rejectsActiveClientsWithoutValidConsent() {
        let missingConsentDTO = completeClientDTO(consentReference: nil)
        let emptyConsentDTO = completeClientDTO(consentReference: " \n ")

        #expect(throws: ClientMapperError.missingConsentReference) {
            try ClientMapper.domain(from: missingConsentDTO)
        }
        #expect(throws: ClientConsentReferenceError.empty) {
            try ClientMapper.domain(from: emptyConsentDTO)
        }
    }

    @Test("Rejects consent attached to inactive client states")
    func rejectsConsentAttachedToInactiveClientStates() {
        for status in [ClientStatusDTO.draft, .consentPendingUpload] {
            let dto = completeClientDTO(status: status)

            #expect(throws: ClientMapperError.unexpectedConsentReference(status)) {
                try ClientMapper.domain(from: dto)
            }
        }
    }
}

private func completeClientDTO(
    id: String = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
    status: ClientStatusDTO = .active,
    consentReference: String? = "consents/ana-alonso/signed.pdf"
) -> ClientDTO {
    ClientDTO(
        id: id,
        displayName: "Ana Alonso",
        taxIdentifier: "12345678Z",
        billingAddress: BillingAddressDTO(
            streetLine: "Calle Bailén, 33",
            postalCode: "41001",
            city: "Sevilla",
            province: "Sevilla"
        ),
        status: status,
        consentReference: consentReference
    )
}

private func decodeClientDTO(_ data: Data) throws -> ClientDTO {
    try JSONDecoder().decode(ClientDTO.self, from: data)
}

private func clientID(_ rawValue: String) throws -> ClientID {
    ClientID(rawValue: try #require(UUID(uuidString: rawValue)))
}
