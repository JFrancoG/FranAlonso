import FirebaseFirestore
import Foundation

/// Server-only immutable Stock feed; constructing the adapter performs no I/O.
actor FirestoreStockRemoteDataSource: StockRemoteDataSource {
    private let fetchDocuments: (StockSyncCursor?) async throws -> [(documentID: String, record: StockRemoteRecord)]
    private let transactMovement: (StockMovement) async throws -> StockRemoteMutationResult

    init(
        fetch: @escaping (StockSyncCursor?) async throws -> [(documentID: String, record: StockRemoteRecord)],
        transact: @escaping (StockMovement) async throws -> StockRemoteMutationResult
    ) {
        fetchDocuments = fetch
        transactMovement = transact
    }

    /// Selects an explicit environment without starting a request.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        let collection = firestore.collection(environment.collectionPath(for: .stockMovements))
        let counter = firestore.document(environment.syncMetadataDocumentPath(for: .stockMovements))
        fetchDocuments = { cursor in
            let query: Query
            if let cursor {
                query = collection.whereField("_sync.changeSequence", isGreaterThan: cursor.changeSequence)
                    .order(by: "_sync.changeSequence")
            } else {
                query = collection
            }
            let snapshot = try await query.getDocuments(source: .server)
            return try snapshot.documents.map { document in
                let dto = try document.data(as: FirestoreStockDocumentDTO.self)
                return (document.documentID, try dto.toRemoteRecord(documentID: document.documentID))
            }
        }
        transactMovement = { movement in
            try await Self.runTransaction(movement, collection: collection, counter: counter, firestore: firestore)
        }
    }

    init(environment: FirestoreEnvironment) {
        self.init(firestore: Firestore.firestore(), environment: environment)
    }

    func fetchChanges(after cursor: StockSyncCursor?) async throws -> StockRemoteChangeBatch {
        try Task.checkCancellation()
        do {
            let previous = cursor?.changeSequence ?? 0
            guard previous >= 0 else { throw StockSyncError.invalidMetadata }
            let documents = try await fetchDocuments(cursor)
            try Task.checkCancellation()
            var ids: Set<UUID> = []
            var sequences: Set<Int64> = []
            let records = try documents.map { document in
                let movement = try document.record.validatedMovement()
                guard document.documentID == movement.id.rawValue.uuidString else {
                    throw StockSyncError.invalidMetadata
                }
                guard document.record.changeSequence > previous,
                    ids.insert(movement.id.rawValue).inserted,
                    sequences.insert(document.record.changeSequence).inserted
                else {
                    throw StockSyncError.invalidBatch
                }
                return document.record
            }
            return StockRemoteChangeBatch(
                records: records,
                nextCursor: StockSyncCursor(changeSequence: sequences.max() ?? previous)
            )
        } catch {
            throw mapFirestoreStockError(error)
        }
    }

    func apply(_ movement: StockMovement) async throws -> StockRemoteMutationResult {
        try Task.checkCancellation()
        do {
            _ = try StockMovementDTO(movement).toDomain()
            let result = try await transactMovement(movement)
            try Task.checkCancellation()
            return result
        } catch {
            throw mapFirestoreStockError(error)
        }
    }
}

extension FirestoreStockRemoteDataSource {
    /// Plans one atomic event/counter create; equivalent replay and divergence emit no writes.
    /// Invalid payload, metadata or an exhausted counter throws before a write pair exists.
    static func transactionPlan(
        for movement: StockMovement,
        against remote: StockRemoteRecord?,
        counter: FirestoreStockCounterState
    ) throws -> FirestoreStockTransactionPlan {
        let dto = try StockMovementDTO(movement)
        _ = try dto.toDomain()
        if let remote {
            let value = try remote.validatedMovement()
            guard value.id == movement.id else { throw StockSyncError.identityConflict }
            return .result(value == movement ? .alreadyApplied(remote) : .conflict(remote))
        }
        let current: Int64
        switch counter {
        case .absent:
            current = 0
        case .value(let value):
            current = value
        case .malformed, .unread:
            throw StockSyncError.invalidMetadata
        }
        guard current >= 0, current < Int64.max else { throw StockSyncError.invalidMetadata }
        let sequence = current + 1
        let record = StockRemoteRecord(
            movement: dto,
            revision: 1,
            operationID: movement.id.rawValue,
            changeSequence: sequence
        )
        return .atomic(
            FirestoreStockAtomicWrite(record: record, counter: FirestoreStockCounterDTO(changeSequence: sequence))
        )
    }

    private static func runTransaction(
        _ movement: StockMovement,
        collection: CollectionReference,
        counter: DocumentReference,
        firestore: Firestore
    ) async throws -> StockRemoteMutationResult {
        let document = collection.document(movement.id.rawValue.uuidString)
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(document)
                    let remote =
                        snapshot.exists
                        ? try snapshot.data(as: FirestoreStockDocumentDTO.self).toRemoteRecord(
                            documentID: snapshot.documentID
                        )
                        : nil
                    let counterState: FirestoreStockCounterState
                    if remote == nil {
                        let counterSnapshot = try transaction.getDocument(counter)
                        if counterSnapshot.exists {
                            do {
                                counterState = .value(
                                    try counterSnapshot.data(as: FirestoreStockCounterDTO.self).changeSequence
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
                    let outcome: StockRemoteMutationResult
                    switch try transactionPlan(for: movement, against: remote, counter: counterState) {
                    case .atomic(let pair):
                        try transaction.setData(
                            from: FirestoreStockDocumentDTO(pair.record),
                            forDocument: document,
                            merge: false
                        )
                        try transaction.setData(from: pair.counter, forDocument: counter, merge: false)
                        outcome = .applied(pair.record)
                    case .result(let result):
                        outcome = result
                    }
                    return try JSONEncoder().encode(outcome)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            } completion: { result, error in
                do {
                    if let error { throw error }
                    guard let data = result as? Data else { throw StockRemoteDataSourceError.unexpected }
                    continuation.resume(returning: try JSONDecoder().decode(StockRemoteMutationResult.self, from: data))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

enum FirestoreStockCounterState {
    case absent
    case value(Int64)
    case malformed, unread
}

struct FirestoreStockCounterDTO: Codable { let changeSequence: Int64 }

struct FirestoreStockAtomicWrite {
    let record: StockRemoteRecord
    let counter: FirestoreStockCounterDTO
}

enum FirestoreStockTransactionPlan {
    case atomic(FirestoreStockAtomicWrite)
    case result(StockRemoteMutationResult)
}

/// Wire document with mandatory immutable sync metadata and no tombstone representation.
struct FirestoreStockDocumentDTO: Codable {
    let movement: StockMovementDTO
    let syncMetadata: FirestoreStockMetadataDTO

    private enum CodingKeys: String, CodingKey {
        case movement
        case syncMetadata = "_sync"
    }
}

extension FirestoreStockDocumentDTO {
    init(_ record: StockRemoteRecord) throws {
        _ = try record.validatedMovement()
        self.init(
            movement: record.movement,
            syncMetadata: FirestoreStockMetadataDTO(
                revision: record.revision,
                operationID: record.operationID.uuidString,
                changeSequence: record.changeSequence
            )
        )
    }

    init(from decoder: any Decoder) throws {
        try stockSyncKeys(decoder, allowed: ["movement", "_sync"])
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            movement: try c.decode(StockMovementDTO.self, forKey: .movement),
            syncMetadata: try c.decode(FirestoreStockMetadataDTO.self, forKey: .syncMetadata)
        )
        _ = try toRemoteRecord(documentID: movement.id)
    }

    /// Requires canonical path identity, revision one and a positive immutable feed position.
    func toRemoteRecord(documentID: String) throws -> StockRemoteRecord {
        guard documentID == movement.id else { throw StockSyncError.invalidMetadata }
        let record = StockRemoteRecord(
            movement: movement,
            revision: syncMetadata.revision,
            operationID: try stockSyncUUID(syncMetadata.operationID),
            changeSequence: syncMetadata.changeSequence
        )
        _ = try record.validatedMovement()
        return record
    }
}

struct FirestoreStockMetadataDTO: Codable {
    let revision: Int64
    let operationID: String
    let changeSequence: Int64

    private enum CodingKeys: String, CodingKey { case revision, operationID, changeSequence }
}

extension FirestoreStockMetadataDTO {
    init(from decoder: any Decoder) throws {
        try stockSyncKeys(decoder, allowed: ["revision", "operationID", "changeSequence"])
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            revision: try c.decode(Int64.self, forKey: .revision),
            operationID: try c.decode(String.self, forKey: .operationID),
            changeSequence: try c.decode(Int64.self, forKey: .changeSequence)
        )
    }
}

private func mapFirestoreStockError(_ error: any Error) -> any Error {
    if error is StockSyncError || error is StockRemoteDataSourceError || error is DecodingError {
        return error
    }
    if error is CancellationError { return CancellationError() }
    let provider = error as NSError
    guard provider.domain == FirestoreErrorDomain else { return StockRemoteDataSourceError.unexpected }
    switch provider.code {
    case FirestoreErrorCode.unavailable.rawValue: return StockRemoteDataSourceError.unavailable
    case FirestoreErrorCode.deadlineExceeded.rawValue: return StockRemoteDataSourceError.deadlineExceeded
    case FirestoreErrorCode.aborted.rawValue: return StockRemoteDataSourceError.aborted
    case FirestoreErrorCode.permissionDenied.rawValue: return StockRemoteDataSourceError.permissionDenied
    case FirestoreErrorCode.resourceExhausted.rawValue: return StockRemoteDataSourceError.resourceExhausted
    case FirestoreErrorCode.cancelled.rawValue: return CancellationError()
    default: return StockRemoteDataSourceError.unexpected
    }
}
