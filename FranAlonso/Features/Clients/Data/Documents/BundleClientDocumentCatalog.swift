import Foundation

/// Resolves versioned legal resources from an explicit bundle, never from a PDF or the process locale.
actor BundleClientDocumentCatalog: ClientDocumentCatalog {
    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func content(
        variant: ClientDocumentVariant,
        version: String,
        language: String
    ) async throws -> ClientDocumentContent {
        try Task.checkCancellation()
        guard let url = bundle.url(forResource: "document-template-content", withExtension: "json") else {
            throw ClientDocumentError.unavailableCatalog
        }
        let manifest: Manifest
        do {
            manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
        } catch {
            throw ClientDocumentError.unavailableCatalog
        }
        guard manifest.supportedLanguages.contains(language),
              let languageURL = bundle.url(forResource: language, withExtension: "lproj"),
              let localizedBundle = Bundle(url: languageURL)
        else { throw ClientDocumentError.unsupportedLanguage }
        let template = variant == .dataInformation ? manifest.dataInformation : manifest.consent
        guard template.documentVersion == version else { throw ClientDocumentError.unsupportedVersion }

        func text(_ key: String) throws -> String {
            let missing = "__missing_legal_localization__"
            let result = localizedBundle.localizedString(forKey: key, value: missing, table: "DocumentTemplates")
            guard result != missing, !result.isEmpty else { throw ClientDocumentError.invalidContent }
            return result
        }

        var sections = [ClientDocumentContent.Section(heading: "", body: try text(template.introductionKey))]
        for row in template.summary {
            sections.append(.init(heading: try text(row.labelKey), body: try text(row.textKey)))
        }
        for row in template.details {
            sections.append(.init(heading: try text(row.headingKey), body: try text(row.textKey)))
        }
        let photo: String?
        switch variant {
        case .dataInformation:
            guard template.optionalConsents.isEmpty else { throw ClientDocumentError.invalidContent }
            photo = nil
        case .informationWithPhoto:
            guard template.optionalConsents.count == 1, let key = template.optionalConsents.first else {
                throw ClientDocumentError.invalidContent
            }
            photo = try text(key)
        }
        try Task.checkCancellation()
        return try ClientDocumentContent(.init(
            version: version,
            language: language,
            title: text(template.titleKey),
            reviewNotice: text(manifest.reviewStatusKey),
            sections: sections,
            photoAuthorization: photo,
            signatureNotice: text(template.signatureNoticeKey),
            labels: .init(
                clientName: text("consent.field.client_name"),
                clientID: text("document.field.client_id"),
                documentID: text("document.field.document_id"),
                version: text("document.field.version"),
                language: text("document.field.language"),
                date: text("document.field.date"),
                signature: text("consent.field.client_signature"),
                authorized: text("document.photo.authorized"),
                purpose: text("document.field.purpose"),
                initialPurpose: text("document.purpose.initial"),
                subsequentPurpose: text("document.purpose.subsequent")
            )
        ))
    }
}

private extension BundleClientDocumentCatalog {
    struct Manifest: Decodable {
        let supportedLanguages: [String]
        let reviewStatusKey: String
        let consent: Template
        let dataInformation: Template
    }

    struct Template: Decodable {
        struct Summary: Decodable {
            let labelKey: String
            let textKey: String
        }

        struct Detail: Decodable {
            let headingKey: String
            let textKey: String
        }

        let titleKey: String
        let introductionKey: String
        let summary: [Summary]
        let details: [Detail]
        let optionalConsents: [String]
        let signatureNoticeKey: String
        let documentVersion: String
    }
}
