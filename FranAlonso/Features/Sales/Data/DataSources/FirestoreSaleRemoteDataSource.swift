import FirebaseFirestore
import Foundation

/// Adapts Firestore Sales documents to the provider-neutral incremental contract.
actor FirestoreSaleRemoteDataSource: SaleRemoteDataSource {
    private let fetchDocuments: (SaleSyncCursor?) async throws -> [
        (documentID: String, record: SaleRemoteRecord)
    ]
    private let transactMutation: (
        SalePendingOperation
    ) async throws -> SaleRemoteMutationResult

    init(
        fetch: @escaping (SaleSyncCursor?) async throws -> [
            (documentID: String, record: SaleRemoteRecord)
        ],
        transact: @escaping (
            SalePendingOperation
        ) async throws -> SaleRemoteMutationResult
    ) {
        fetchDocuments = fetch
        transactMutation = transact
    }

    /// Creates the adapter for the Sales collection in an explicitly selected environment.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        let collection = firestore.collection(
            environment.collectionPath(for: .sales)
        )
        let counterDocument = firestore.document(
            environment.syncMetadataDocumentPath(for: .sales)
        )
        let policy = SaleSyncPolicy()

        fetchDocuments = { cursor in
            let query: Query
            if let cursor {
                query = collection
                    .whereField(
                        "_sync.changeSequence",
                        isGreaterThan: cursor.changeSequence
                    )
                    .order(by: "_sync.changeSequence")
            } else {
                query = collection
            }
            let snapshot = try await query.getDocuments(source: .server)
            return try snapshot.documents.map { document in
                let payload = try document.data(
                    as: FirestoreSaleDocumentDTO.self
                )
                return (
                    documentID: document.documentID,
                    record: try payload.toRemoteRecord(
                        documentID: document.documentID
                    )
                )
            }
        }
        transactMutation = { operation in
            try await Self.runTransaction(
                operation,
                collection: collection,
                counterDocument: counterDocument,
                firestore: firestore,
                policy: policy
            )
        }
    }

    /// Creates the live adapter after the default Firebase app has been configured.
    init(environment: FirestoreEnvironment) {
        self.init(
            firestore: Firestore.firestore(),
            environment: environment
        )
    }

    func fetchChanges(
        after cursor: SaleSyncCursor?
    ) async throws -> SaleRemoteChangeBatch {
        do {
            let documents = try await fetchDocuments(cursor)
            let records = try documents.map { document in
                guard document.documentID == document.record.id else {
                    throw saleDocumentDecodingError(
                        codingPath: [SaleDocumentCodingKey.id],
                        description: "The sale identifier does not match its document path."
                    )
                }
                if let sequence = document.record.changeSequence {
                    guard sequence > 0 else {
                        throw SaleSyncPolicyError.invalidChangeSequence
                    }
                } else if cursor != nil {
                    throw SaleSyncPolicyError.invalidChangeSequence
                }
                return document.record
            }
            let nextSequence = records.compactMap(\.changeSequence).max()
                ?? cursor?.changeSequence
                ?? 0
            return SaleRemoteChangeBatch(
                records: records,
                nextCursor: SaleSyncCursor(
                    changeSequence: nextSequence
                )
            )
        } catch {
            throw mapFirestoreSaleError(error)
        }
    }

    func apply(
        _ operation: SalePendingOperation
    ) async throws -> SaleRemoteMutationResult {
        do {
            if case .upsert(let upsert) = operation {
                guard UUID(uuidString: upsert.sale.id) == upsert.saleID else {
                    throw SaleSyncPolicyError.entityIdentityMismatch
                }
            }
            return try await transactMutation(operation)
        } catch {
            throw mapFirestoreSaleError(error)
        }
    }
}

extension FirestoreSaleRemoteDataSource {
    /// Returns the next counter value, treating an absent counter as zero.
    ///
    /// - Throws: A typed policy error for negative or exhausted counter state.
    static func nextChangeSequence(after current: Int64?) throws -> Int64 {
        let current = current ?? 0
        guard current >= 0 else {
            throw SaleSyncPolicyError.invalidChangeSequence
        }
        guard current < Int64.max else {
            throw SaleSyncPolicyError.changeSequenceOverflow
        }
        return current + 1
    }

    private static func runTransaction(
        _ operation: SalePendingOperation,
        collection: CollectionReference,
        counterDocument: DocumentReference,
        firestore: Firestore,
        policy: SaleSyncPolicy
    ) async throws -> SaleRemoteMutationResult {
        let document = collection.document(operation.saleID.uuidString)
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(document)
                    let remoteRecord: SaleRemoteRecord?
                    if snapshot.exists {
                        remoteRecord = try snapshot.data(
                            as: FirestoreSaleDocumentDTO.self
                        ).toRemoteRecord(documentID: snapshot.documentID)
                    } else {
                        remoteRecord = nil
                    }

                    let decision = policy.decision(
                        for: operation,
                        against: remoteRecord
                    )
                    let counterState: FirestoreSaleCounterState
                    if case .apply = decision {
                        let counterSnapshot = try transaction.getDocument(
                            counterDocument
                        )
                        if counterSnapshot.exists {
                            do {
                                counterState = .value(
                                    try counterSnapshot.data(
                                        as: FirestoreSaleCounterDTO.self
                                    ).changeSequence
                                )
                            } catch is DecodingError {
                                counterState = .malformed
                            }
                        } else {
                            counterState = .absent
                        }
                    } else {
                        counterState = .unread
                    }

                    let outcome: FirestoreSaleTransactionOutcome
                    switch try transactionPlan(
                        for: operation,
                        against: remoteRecord,
                        counter: counterState,
                        policy: policy
                    ) {
                    case .atomic(let write):
                        try transaction.setData(
                            from: FirestoreSaleWriteDTO(write.record),
                            forDocument: document,
                            merge: false
                        )
                        try transaction.setData(
                            from: write.counter,
                            forDocument: counterDocument,
                            merge: false
                        )
                        outcome = .result(.applied(write.record))
                    case .result(let result):
                        outcome = .result(result)
                    case .invalid(let error):
                        outcome = .invalid(error)
                    }
                    return try JSONEncoder().encode(outcome)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            } completion: { encodedOutcome, error in
                do {
                    if let error { throw error }
                    guard let outcomeData = encodedOutcome as? Data else {
                        throw SaleRemoteDataSourceError.unexpected
                    }
                    switch try JSONDecoder().decode(
                        FirestoreSaleTransactionOutcome.self,
                        from: outcomeData
                    ) {
                    case .result(let result):
                        continuation.resume(returning: result)
                    case .invalid(let error):
                        continuation.resume(throwing: error)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Plans the provider transaction before either Firestore write is emitted.
    ///
    /// A mutation requiring a write returns one inseparable sale-and-counter pair. Invalid
    /// counter state throws before a write plan exists; idempotent and conflict outcomes do
    /// not read or advance the counter.
    static func transactionPlan(
        for operation: SalePendingOperation,
        against remoteRecord: SaleRemoteRecord?,
        counter: FirestoreSaleCounterState,
        policy: SaleSyncPolicy
    ) throws -> FirestoreSaleTransactionPlan {
        switch policy.decision(for: operation, against: remoteRecord) {
        case .apply(let recordWithoutSequence):
            let currentSequence: Int64?
            switch counter {
            case .absent:
                currentSequence = nil
            case .value(let value):
                currentSequence = value
            case .malformed, .unread:
                throw SaleSyncPolicyError.invalidChangeSequence
            }
            let nextSequence = try nextChangeSequence(
                after: currentSequence
            )
            let record = recordWithoutSequence.withChangeSequence(
                nextSequence
            )
            return .atomic(
                FirestoreSaleAtomicWrite(
                    record: record,
                    counter: FirestoreSaleCounterDTO(
                        changeSequence: nextSequence
                    )
                )
            )
        case .alreadyApplied(let record):
            return .result(.alreadyApplied(record))
        case .conflict(let reason, let record):
            return .result(.conflict(reason, record))
        case .invalid(let error):
            return .invalid(error)
        }
    }
}

struct FirestoreSaleWriteDTO: Encodable {
    private let payloadVersion: Int
    private let id: String
    private let isDeleted: Bool
    private let clientID: String?
    private let createdAt: SaleTimestampDTO?
    private let lines: [SaleLineDTO]?
    private let status: SaleStatusDTO?
    private let syncMetadata: FirestoreSaleSyncWriteDTO

    private enum CodingKeys: String, CodingKey {
        case payloadVersion
        case id
        case isDeleted = "_deleted"
        case clientID
        case createdAt
        case lines
        case status
        case syncMetadata = "_sync"
    }
}

extension FirestoreSaleWriteDTO {
    /// Encodes a complete live document or business-field-free tombstone from an authoritative record.
    init(_ record: SaleRemoteRecord) throws {
        guard let sequence = record.changeSequence, sequence > 0,
              case .versioned(let revision, let operationID) = record.version else {
            throw SaleSyncPolicyError.invalidChangeSequence
        }
        let syncMetadata = FirestoreSaleSyncWriteDTO(
            revision: revision,
            lastOperationID: operationID.uuidString,
            changeSequence: sequence
        )
        switch record.content {
        case .live(let sale):
            _ = try sale.toDomain()
            self.init(
                payloadVersion: SaleDTO.currentPayloadVersion,
                id: sale.id,
                isDeleted: false,
                clientID: sale.clientID,
                createdAt: sale.createdAt,
                lines: sale.lines,
                status: sale.status,
                syncMetadata: syncMetadata
            )
        case .tombstone(let saleID):
            self.init(
                payloadVersion: SaleDTO.currentPayloadVersion,
                id: saleID.uuidString,
                isDeleted: true,
                clientID: nil,
                createdAt: nil,
                lines: nil,
                status: nil,
                syncMetadata: syncMetadata
            )
        }
    }
}

struct FirestoreSaleSyncWriteDTO: Encodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64
}

struct FirestoreSaleDocumentDTO: Decodable {
    let payloadVersion: Int?
    let id: String
    let isDeleted: Bool?
    let clientID: String?
    let createdAt: SaleTimestampDTO?
    let lines: [SaleLineDTO]?
    let status: SaleStatusDTO?
    let syncMetadata: FirestoreSaleSyncMetadataDTO?

    private enum CodingKeys: String, CodingKey {
        case payloadVersion
        case id
        case isDeleted = "_deleted"
        case clientID
        case createdAt
        case lines
        case status
        case syncMetadata = "_sync"
    }

    /// Reconstructs a provider-neutral live record or tombstone after validating metadata.
    func toRemoteRecord(documentID: String) throws -> SaleRemoteRecord {
        guard documentID == id, let saleID = UUID(uuidString: id) else {
            throw saleDocumentDecodingError(
                codingPath: [SaleDocumentCodingKey.id],
                description: "The sale identifier does not match its document path."
            )
        }
        let version = try remoteVersion()
        let changeSequence = try validatedChangeSequence()

        if isDeleted == true {
            guard payloadVersion == SaleDTO.currentPayloadVersion else {
                throw saleDocumentDecodingError(
                    codingPath: [SaleDocumentCodingKey.payloadVersion],
                    description: "A Sale tombstone requires payload version 1."
                )
            }
            guard syncMetadata != nil else {
                throw saleDocumentDecodingError(
                    codingPath: [SaleDocumentCodingKey.syncMetadata],
                    description: "A tombstone requires authoritative sync metadata."
                )
            }
            guard clientID == nil, createdAt == nil, lines == nil, status == nil else {
                throw saleDocumentDecodingError(
                    codingPath: [SaleDocumentCodingKey.isDeleted],
                    description: "A Sale tombstone cannot carry business fields."
                )
            }
            return SaleRemoteRecord(
                content: .tombstone(saleID: saleID),
                version: version,
                changeSequence: changeSequence
            )
        }

        let sale = try validatedLiveSale()
        return SaleRemoteRecord(
            content: .live(sale),
            version: version,
            changeSequence: changeSequence
        )
    }

    private func validatedLiveSale() throws -> SaleDTO {
        guard let payloadVersion else {
            throw missingSaleField(.payloadVersion)
        }
        guard payloadVersion == SaleDTO.currentPayloadVersion else {
            throw saleDocumentDecodingError(
                codingPath: [SaleDocumentCodingKey.payloadVersion],
                description: "The Sale payload version is unsupported."
            )
        }
        guard let createdAt else {
            throw missingSaleField(.createdAt)
        }
        guard let lines else {
            throw missingSaleField(.lines)
        }
        guard let status else {
            throw missingSaleField(.status)
        }
        let sale = SaleDTO(
            payloadVersion: payloadVersion,
            id: id,
            clientID: clientID,
            createdAt: createdAt,
            lines: lines,
            status: status
        )
        do {
            _ = try sale.toDomain()
        } catch {
            throw saleBusinessDecodingError(error)
        }
        return sale
    }

    private func remoteVersion() throws -> SaleRemoteVersion {
        guard let syncMetadata else { return .legacy }
        guard syncMetadata.revision > 0 else {
            throw saleDocumentDecodingError(
                codingPath: [
                    SaleDocumentCodingKey.syncMetadata,
                    SaleDocumentCodingKey.revision
                ],
                description: "A synchronized sale revision must be positive."
            )
        }
        guard let operationID = UUID(
            uuidString: syncMetadata.lastOperationID
        ) else {
            throw saleDocumentDecodingError(
                codingPath: [
                    SaleDocumentCodingKey.syncMetadata,
                    SaleDocumentCodingKey.lastOperationID
                ],
                description: "The synchronized sale operation identifier is invalid."
            )
        }
        return .versioned(
            revision: syncMetadata.revision,
            lastOperationID: operationID
        )
    }

    private func validatedChangeSequence() throws -> Int64? {
        guard let sequence = syncMetadata?.changeSequence else { return nil }
        guard sequence > 0 else {
            throw saleDocumentDecodingError(
                codingPath: [
                    SaleDocumentCodingKey.syncMetadata,
                    SaleDocumentCodingKey.changeSequence
                ],
                description: "A synchronized change sequence must be positive."
            )
        }
        return sequence
    }

    private func missingSaleField(
        _ key: SaleDocumentCodingKey
    ) -> DecodingError {
        saleDocumentDecodingError(
            codingPath: [key],
            description: "A live sale requires \(key.stringValue)."
        )
    }
}

extension FirestoreSaleDocumentDTO {
    init(from decoder: any Decoder) throws {
        let strictContainer = try decoder.container(
            keyedBy: FirestoreSaleDynamicCodingKey.self
        )
        let allowedKeys: Set<String> = [
            CodingKeys.payloadVersion.rawValue,
            CodingKeys.id.rawValue,
            CodingKeys.isDeleted.rawValue,
            CodingKeys.clientID.rawValue,
            CodingKeys.createdAt.rawValue,
            CodingKeys.lines.rawValue,
            CodingKeys.status.rawValue,
            CodingKeys.syncMetadata.rawValue
        ]
        guard Set(strictContainer.allKeys.map(\.stringValue))
                .isSubset(of: allowedKeys) else {
            throw saleDocumentDecodingError(
                codingPath: decoder.codingPath,
                description: "The Sale document contains an unexpected root field."
            )
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decodeIfPresent(
                Int.self,
                forKey: .payloadVersion
            ),
            id: try container.decode(String.self, forKey: .id),
            isDeleted: try container.decodeIfPresent(Bool.self, forKey: .isDeleted),
            clientID: try container.decodeIfPresent(String.self, forKey: .clientID),
            createdAt: try container.decodeIfPresent(
                SaleTimestampDTO.self,
                forKey: .createdAt
            ),
            lines: try container.decodeIfPresent(
                [SaleLineDTO].self,
                forKey: .lines
            ),
            status: try container.decodeIfPresent(SaleStatusDTO.self, forKey: .status),
            syncMetadata: try container.decodeIfPresent(
                FirestoreSaleSyncMetadataDTO.self,
                forKey: .syncMetadata
            )
        )
    }
}

private struct FirestoreSaleDynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

struct FirestoreSaleSyncMetadataDTO: Decodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64?
}

struct FirestoreSaleCounterDTO: Codable, Equatable {
    let changeSequence: Int64
}

enum FirestoreSaleCounterState: Equatable {
    case unread
    case absent
    case value(Int64)
    case malformed
}

struct FirestoreSaleAtomicWrite: Equatable {
    let record: SaleRemoteRecord
    let counter: FirestoreSaleCounterDTO
}

enum FirestoreSaleTransactionPlan: Equatable {
    case atomic(FirestoreSaleAtomicWrite)
    case result(SaleRemoteMutationResult)
    case invalid(SaleSyncPolicyError)

    var atomicWrite: FirestoreSaleAtomicWrite? {
        guard case .atomic(let write) = self else { return nil }
        return write
    }
}

private enum FirestoreSaleTransactionOutcome: Codable {
    case result(SaleRemoteMutationResult)
    case invalid(SaleSyncPolicyError)
}

private enum SaleDocumentCodingKey: String, CodingKey {
    case payloadVersion
    case id
    case isDeleted = "_deleted"
    case clientID
    case createdAt
    case lines
    case linkedProductID
    case serviceID
    case unitPrice
    case amount
    case taxRate
    case discount
    case status
    case payment
    case document
    case reversal
    case syncMetadata = "_sync"
    case revision
    case lastOperationID
    case changeSequence
}

private extension SaleRemoteRecord {
    func withChangeSequence(_ changeSequence: Int64) -> SaleRemoteRecord {
        SaleRemoteRecord(
            content: content,
            version: version,
            changeSequence: changeSequence
        )
    }
}

private func saleDocumentDecodingError(
    codingPath: [any CodingKey],
    description: String
) -> DecodingError {
    DecodingError.dataCorrupted(
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: description
        )
    )
}

private func saleBusinessDecodingError(
    _ error: any Error
) -> DecodingError {
    let codingPath: [any CodingKey]
    switch error {
    case let SaleMappingError.invalidIdentifier(_, location):
        codingPath = saleIdentifierCodingPath(location)
    case SaleMappingError.moneyNormalizationChanged,
         is MoneyError:
        codingPath = [
            SaleDocumentCodingKey.lines,
            SaleDocumentCodingKey.unitPrice,
            SaleDocumentCodingKey.amount
        ]
    case is TaxRateError:
        codingPath = [
            SaleDocumentCodingKey.lines,
            SaleDocumentCodingKey.taxRate,
        ]
    case is DiscountError:
        codingPath = [
            SaleDocumentCodingKey.lines,
            SaleDocumentCodingKey.discount,
        ]
    case is SaleError:
        codingPath = [SaleDocumentCodingKey.status]
    default:
        codingPath = []
    }
    return saleDocumentDecodingError(
        codingPath: codingPath,
        description: "The sale business snapshot violates its Domain contract."
    )
}

private func saleIdentifierCodingPath(
    _ location: SaleIdentifierLocation
) -> [any CodingKey] {
    switch location {
    case .sale:
        [SaleDocumentCodingKey.id]
    case .client:
        [SaleDocumentCodingKey.clientID]
    case .line(let index):
        [
            SaleDocumentCodingKey.lines,
            SaleDocumentIndexCodingKey(index),
            SaleDocumentCodingKey.id
        ]
    case .service(let lineIndex):
        [
            SaleDocumentCodingKey.lines,
            SaleDocumentIndexCodingKey(lineIndex),
            SaleDocumentCodingKey.serviceID
        ]
    case .linkedProduct(let lineIndex):
        [
            SaleDocumentCodingKey.lines,
            SaleDocumentIndexCodingKey(lineIndex),
            SaleDocumentCodingKey.linkedProductID
        ]
    case .payment:
        [
            SaleDocumentCodingKey.status,
            SaleDocumentCodingKey.payment,
            SaleDocumentCodingKey.id
        ]
    case .document:
        [
            SaleDocumentCodingKey.status,
            SaleDocumentCodingKey.document,
            SaleDocumentCodingKey.id
        ]
    case .reversal:
        [
            SaleDocumentCodingKey.status,
            SaleDocumentCodingKey.reversal,
            SaleDocumentCodingKey.id
        ]
    }
}

private struct SaleDocumentIndexCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ index: Int) {
        stringValue = "Index \(index)"
        intValue = index
    }

    init?(stringValue: String) {
        return nil
    }

    init?(intValue: Int) {
        self.init(intValue)
    }
}

private func mapFirestoreSaleError(_ error: any Error) -> any Error {
    if error is DecodingError || error is SaleSyncPolicyError {
        return error
    }
    if error is CancellationError { return CancellationError() }

    let providerError = error as NSError
    guard providerError.domain == FirestoreErrorDomain else {
        return SaleRemoteDataSourceError.unexpected
    }
    switch providerError.code {
    case FirestoreErrorCode.deadlineExceeded.rawValue:
        return SaleRemoteDataSourceError.deadlineExceeded
    case FirestoreErrorCode.permissionDenied.rawValue:
        return SaleRemoteDataSourceError.permissionDenied
    case FirestoreErrorCode.resourceExhausted.rawValue:
        return SaleRemoteDataSourceError.resourceExhausted
    case FirestoreErrorCode.aborted.rawValue:
        return SaleRemoteDataSourceError.aborted
    case FirestoreErrorCode.unavailable.rawValue:
        return SaleRemoteDataSourceError.unavailable
    case FirestoreErrorCode.cancelled.rawValue:
        return CancellationError()
    default:
        return SaleRemoteDataSourceError.unexpected
    }
}
