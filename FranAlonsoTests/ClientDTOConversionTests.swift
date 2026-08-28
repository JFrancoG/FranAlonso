import Foundation
import Testing
@testable import FranAlonso

@Suite("Client DTO conversions")
struct ClientDTOConversionTests {
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

    @Test("Rejects an invalid client identifier")
    func rejectsAnInvalidClientIdentifier() {
        let dto = completeClientDTO(id: "not-a-uuid")

        #expect(throws: ClientMappingError.invalidIdentifier("not-a-uuid")) {
            try dto.toDomain()
        }
    }

    @Test("Rejects active clients without valid consent")
    func rejectsActiveClientsWithoutValidConsent() {
        let missingConsentDTO = completeClientDTO(consentReference: nil)
        let emptyConsentDTO = completeClientDTO(consentReference: " \n ")

        #expect(throws: ClientMappingError.missingConsentReference) {
            try missingConsentDTO.toDomain()
        }
        #expect(throws: ClientConsentReferenceError.empty) {
            try emptyConsentDTO.toDomain()
        }
    }

    @Test("Rejects consent attached to inactive client states")
    func rejectsConsentAttachedToInactiveClientStates() {
        for status in [ClientStatusDTO.draft, .consentPendingUpload] {
            let dto = completeClientDTO(status: status)

            #expect(throws: ClientMappingError.unexpectedConsentReference(status)) {
                try dto.toDomain()
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
