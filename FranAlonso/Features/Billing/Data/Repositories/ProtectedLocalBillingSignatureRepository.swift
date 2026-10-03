import CryptoKit
import Foundation

/// Keeps an optional private image per principal, with complete file protection and no backup.
///
/// Authorization is checked before access and before bytes are returned or an import is published.
/// Rejected imports preserve the previous resource, including when Foundation has already moved its original file.
/// A pending protected recovery copy remains authoritative until restoration or publication is verified.
/// No real image is loaded during composition. All filesystem access belongs to the shared cache coordinator.
struct ProtectedLocalBillingSignatureRepository: BillingBusinessSignatureRepository {
    private let access: BillingAssetAccess
    private let directory: URL
    private let protectionCheck: @Sendable (URL) throws -> Void
    private let publicationReplace: @Sendable (URL, URL) throws -> Void

    func loadSignature() async throws -> Data? {
        do {
            return try await BillingSignatureCacheCoordinator.shared.load(access: access) {
                try readSignature()
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as BillingAssetError {
            throw error
        } catch {
            throw BillingAssetError.signatureUnavailable
        }
    }

    func importSignature(_ data: Data) async throws {
        do {
            try await BillingSignatureCacheCoordinator.shared.publish(
                access: access,
                prepare: {
                    try prepareCandidate(data)
                },
                commit: { candidate in
                    try publishCandidate(candidate)
                },
                discard: { candidate in
                    try? FileManager.default.removeItem(at: candidate)
                }
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as BillingAssetError {
            throw error
        } catch {
            throw BillingAssetError.signatureUnavailable
        }
    }

    private var principalDirectory: URL {
        let digest = SHA256.hash(data: Data(access.principalID.utf8))
        let name = digest.map { byte in
            let hex = String(byte, radix: 16)
            return hex.count == 1 ? "0" + hex : hex
        }.joined()
        return directory.appending(path: name, directoryHint: .isDirectory)
    }

    private var signatureURL: URL { principalDirectory.appending(path: "business-signature") }
    private var recoveryURL: URL { principalDirectory.appending(path: ".previous-signature") }

    private func readSignature() throws -> Data? {
        try validateLocation()
        guard try validateExistingDirectories() else { return nil }
        let source: URL
        if try itemType(at: recoveryURL) != nil {
            source = recoveryURL
        } else if try itemType(at: signatureURL) != nil {
            source = signatureURL
        } else {
            return nil
        }
        let bytes = try readProtectedBytes(source)
        try BillingSignatureImageValidator.validate(bytes)
        return bytes
    }

    private func prepareCandidate(_ data: Data) throws -> URL {
        try BillingSignatureImageValidator.validate(data)
        try validateLocation()
        try prepareDirectory(directory)
        try prepareDirectory(principalDirectory)
        if try itemType(at: recoveryURL) != nil {
            try validateProtectedItem(recoveryURL, expectedType: .typeRegular)
            try validateDestinationTypeIfPresent()
        } else {
            try validateDestinationIfPresent()
        }
        let candidate = principalDirectory.appending(path: ".candidate-" + UUID().uuidString)
        do {
            try writeProtectedBytes(data, to: candidate)
            return candidate
        } catch {
            try? FileManager.default.removeItem(at: candidate)
            throw error
        }
    }

    private func publishCandidate(_ candidate: URL) throws {
        try validateLocation()
        guard try validateExistingDirectories() else { throw BillingAssetError.signatureUnavailable }
        try validateProtectedItem(candidate, expectedType: .typeRegular)
        if try itemType(at: recoveryURL) != nil {
            try restorePreviousSignature()
        }
        try validateDestinationIfPresent()
        let hadPrevious = try itemType(at: signatureURL) != nil
        if hadPrevious {
            // Capture after the final authorization await: another instance may have published while it suspended.
            let previous = try readProtectedBytes(signatureURL)
            do {
                try writeProtectedBytes(previous, to: recoveryURL)
            } catch {
                try? FileManager.default.removeItem(at: recoveryURL)
                throw error
            }
        }
        do {
            if hadPrevious {
                try publicationReplace(signatureURL, candidate)
            } else {
                try FileManager.default.moveItem(at: candidate, to: signatureURL)
            }
            try excludeFromBackup(signatureURL)
            try validateProtectedItem(signatureURL, expectedType: .typeRegular)
            if hadPrevious {
                try FileManager.default.removeItem(at: recoveryURL)
            }
        } catch {
            if hadPrevious {
                // Failed verification or restoration leaves the protected recovery copy available on reopening.
                try? restorePreviousSignature()
            } else {
                try? FileManager.default.removeItem(at: signatureURL)
            }
            throw error
        }
    }

    private func restorePreviousSignature() throws {
        let previous = try readProtectedBytes(recoveryURL)
        try validateDestinationTypeIfPresent()
        try writeProtectedBytes(previous, to: signatureURL)
        try FileManager.default.removeItem(at: recoveryURL)
    }

    private func readProtectedBytes(_ url: URL) throws -> Data {
        try validateProtectedItem(url, expectedType: .typeRegular)
        let bytes = try BillingAssetFileReader.read(
            url,
            maximumByteCount: BillingSignatureImageValidator.maximumByteCount
        )
        guard bytes.count <= BillingSignatureImageValidator.maximumByteCount else {
            throw BillingAssetError.invalidSignature
        }
        return bytes
    }

    private func writeProtectedBytes(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        try excludeFromBackup(url)
        try validateProtectedItem(url, expectedType: .typeRegular)
    }

    private func validateLocation() throws {
        guard directory.isFileURL else { throw BillingAssetError.signatureUnavailable }
        let paths = [directory.standardizedFileURL, directory.resolvingSymlinksInPath().standardizedFileURL]
        for path in paths {
            guard !path.pathComponents.contains(where: { component in
                ["app", "bundle", "framework"].contains(component.split(separator: ".").last?.lowercased() ?? "")
            }) else { throw BillingAssetError.signatureUnavailable }
        }
    }

    private func validateExistingDirectories() throws -> Bool {
        guard try itemType(at: directory) != nil else { return false }
        try validateProtectedItem(directory, expectedType: .typeDirectory)
        guard try itemType(at: principalDirectory) != nil else { return false }
        try validateProtectedItem(principalDirectory, expectedType: .typeDirectory)
        return true
    }

    private func prepareDirectory(_ url: URL) throws {
        if try itemType(at: url) != nil {
            try validateProtectedItem(url, expectedType: .typeDirectory)
            return
        }
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        try excludeFromBackup(url)
        try validateProtectedItem(url, expectedType: .typeDirectory)
    }

    private func validateDestinationIfPresent() throws {
        if try itemType(at: signatureURL) != nil {
            try validateProtectedItem(signatureURL, expectedType: .typeRegular)
        }
    }

    private func validateDestinationTypeIfPresent() throws {
        if let type = try itemType(at: signatureURL), type != .typeRegular {
            throw BillingAssetError.signatureUnavailable
        }
    }

    private func itemType(at url: URL) throws -> FileAttributeType? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.type] as? FileAttributeType
        } catch {
            let error = error as NSError
            if error.domain == NSCocoaErrorDomain,
               [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(error.code) {
                return nil
            }
            throw error
        }
    }

    private func validateProtectedItem(_ url: URL, expectedType: FileAttributeType) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let freshURL = URL(filePath: url.path)
        guard attributes[.type] as? FileAttributeType == expectedType,
              try freshURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true else {
            throw BillingAssetError.signatureUnavailable
        }
        try protectionCheck(freshURL)
    }

    /// The production default denies access when protection cannot be established, including Simulator's nil.
    private static func verifySystemFileProtection(_ url: URL) throws {
        guard try url.resourceValues(forKeys: [.fileProtectionKey]).fileProtection == .complete else {
            throw BillingAssetError.signatureUnavailable
        }
    }

    private static func replaceSignatureFile(_ original: URL, _ candidate: URL) throws {
        _ = try FileManager.default.replaceItemAt(
            original,
            withItemAt: candidate,
            backupItemName: nil,
            options: .usingNewMetadataOnly
        )
    }

    private func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }
}

extension ProtectedLocalBillingSignatureRepository {
    init(
        access: BillingAssetAccess,
        directory: URL,
        verifyFileProtection: @escaping @Sendable (URL) throws -> Void = verifySystemFileProtection,
        replaceFile: @escaping @Sendable (URL, URL) throws -> Void = replaceSignatureFile
    ) {
        self.access = access
        self.directory = directory
        protectionCheck = verifyFileProtection
        publicationReplace = replaceFile
    }
}
