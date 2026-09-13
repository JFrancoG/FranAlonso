import Foundation

extension ClientDocumentPersistenceActor {
    func beginUpload(id: UUID, at date: Date) throws -> ClientDocumentDelivery {
        try transaction {
            guard let model = try documentModel(id: id) else { throw ClientDocumentPersistenceError.notFound }
            let delivery = try model.toDomain()
            switch delivery.state {
            case .uploaded:
                return delivery
            case .conflict:
                throw ClientDocumentStorageError.conflict
            case .pending, .failed:
                guard model.attemptCount < Int.max, date.timeIntervalSince1970.isFinite else {
                    throw ClientDocumentPersistenceError.invalidPayload
                }
                model.attemptCount += 1
                model.lastAttemptAt = date
                try model.setState(.pending)
                return try model.toDomain()
            }
        }
    }

    func completeUpload(
        id: UUID,
        receipt: ClientDocumentUploadReceipt,
        principalID: String
    ) throws -> ClientDocumentUploadReceipt {
        try transaction {
            guard receipt.matches(documentID: id, principalID: principalID) else {
                throw ClientDocumentStorageError.invalidReceipt
            }
            guard let model = try documentModel(id: id) else { throw ClientDocumentPersistenceError.notFound }
            switch try model.toDomain().state {
            case .uploaded(let accepted):
                guard accepted == receipt else { throw ClientDocumentStorageError.invalidReceipt }
                return accepted
            case .conflict:
                throw ClientDocumentStorageError.conflict
            case .pending, .failed:
                try model.setState(.uploaded(receipt))
                return receipt
            }
        }
    }

    func recordUploadFailure(id: UUID, attempt: Int, error: ClientDocumentStorageError) throws {
        try transaction {
            guard let model = try documentModel(id: id) else { throw ClientDocumentPersistenceError.notFound }
            switch try model.toDomain().state {
            case .uploaded, .conflict:
                return
            case .pending, .failed:
                guard error == .conflict || model.attemptCount == attempt else { return }
                try model.setState(error == .conflict ? .conflict(receipt: nil) : .failed(error))
            }
        }
    }
}
