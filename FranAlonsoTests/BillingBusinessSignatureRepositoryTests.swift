import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import FranAlonso

@Suite("Private billing signature assets")
struct BillingBusinessSignatureRepositoryTests {
    @Test("An absent signature is optional and creates no private directory")
    func absentSignature() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        #expect(try await fixture.repository().loadSignature() == nil)
        #expect(!FileManager.default.fileExists(atPath: fixture.directory.path))
    }

    @Test("PNG and JPEG imports preserve exact bytes through reopening", arguments: [UTType.png, .jpeg])
    func importAndReopen(type: UTType) async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let bytes = try signatureImage(type: type)
        try await fixture.repository().importSignature(bytes)
        #expect(try await fixture.repository().loadSignature() == bytes)
        let file = try fixture.cachedFile()
        let ancestors = [fixture.directory, file.deletingLastPathComponent(), file]
        for url in ancestors {
            #expect(try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
        }
        #expect(!file.path.contains("private-principal"))
        #expect(try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path).count == 1)
    }

    @Test(
        "Invalid imports preserve the previous image",
        arguments: [
            Data(),
            Data("not an image".utf8),
            Data(repeating: 0, count: 2_097_153)
        ]
    )
    func invalidImportPreservesPrevious(bytes: Data) async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let previous = try signatureImage(type: .png)
        let repository = fixture.repository()
        try await repository.importSignature(previous)
        await #expect(throws: BillingAssetError.invalidSignature) {
            try await repository.importSignature(bytes)
        }
        #expect(try await repository.loadSignature() == previous)
    }

    @Test("A principal cannot load another principal's cached image")
    func principalIsolation() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let bytes = try signatureImage(type: .png)
        try await fixture.repository().importSignature(bytes)
        #expect(try await fixture.repository(principal: "another-principal").loadSignature() == nil)
        #expect(try await fixture.repository().loadSignature() == bytes)
    }

    @Test("Revoked access rejects both reads and imports before creating files")
    func unauthorizedOperations() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        await fixture.permit.revoke()
        await #expect(throws: BillingAssetError.unauthorized) {
            try await repository.loadSignature()
        }
        let bytes = try signatureImage(type: .png)
        await #expect(throws: BillingAssetError.unauthorized) {
            try await repository.importSignature(bytes)
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.directory.path))
    }

    @Test("Revocation during a late read never releases cached bytes", arguments: [false, true])
    func revokedLateRead(hasImage: Bool) async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        if hasImage {
            try await repository.importSignature(signatureImage(type: .png))
        }
        await fixture.permit.blockSecondNextValidation()
        let read = Task {
            try await repository.loadSignature()
        }
        await fixture.permit.waitUntilBlocked()
        await fixture.permit.revokeAndRelease()
        await #expect(throws: BillingAssetError.unauthorized) {
            try await read.value
        }
    }

    @Test("Cancellation before publication preserves the previous image")
    func canceledImport() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        let previous = try signatureImage(type: .png)
        try await repository.importSignature(previous)
        await fixture.permit.blockSecondNextValidation()
        let replacement = try signatureImage(type: .jpeg)
        let operation = Task {
            try await repository.importSignature(replacement)
        }
        await fixture.permit.waitUntilBlocked()
        operation.cancel()
        await fixture.permit.release()
        await #expect(throws: CancellationError.self) {
            try await operation.value
        }
        #expect(try await repository.loadSignature() == previous)
        let file = try fixture.cachedFile()
        #expect(try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path).count == 1)
    }

    @Test("Revocation before publication preserves the previous image and removes the candidate")
    func revokedImport() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let previous = try signatureImage(type: .png)
        let repository = fixture.repository()
        try await repository.importSignature(previous)
        await fixture.permit.blockSecondNextValidation()
        let replacement = try signatureImage(type: .jpeg)
        let operation = Task {
            try await repository.importSignature(replacement)
        }
        await fixture.permit.waitUntilBlocked()
        await fixture.permit.revokeAndRelease()
        await #expect(throws: BillingAssetError.unauthorized) {
            try await operation.value
        }
        #expect(try Data(contentsOf: fixture.cachedFile()) == previous)
        let file = try fixture.cachedFile()
        #expect(try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path).count == 1)
    }

    @Test("Corrupt cached bytes fail recoverably and a later valid import repairs them")
    func corruptedCacheRecovery() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        let bytes = try signatureImage(type: .png)
        try await repository.importSignature(bytes)
        let file = try fixture.cachedFile()
        let handle = try FileHandle(forWritingTo: file)
        try handle.truncate(atOffset: 0)
        try handle.write(contentsOf: Data("corrupt".utf8))
        try handle.close()
        await #expect(throws: BillingAssetError.invalidSignature) {
            try await repository.loadSignature()
        }
        try await repository.importSignature(bytes)
        #expect(try await repository.loadSignature() == bytes)
    }

    @Test("Insecure cache metadata is rejected", arguments: [false, true])
    func insecureMetadata(backup: Bool) async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        try await repository.importSignature(signatureImage(type: .png))
        let file = try fixture.cachedFile()
        if backup {
            var values = URLResourceValues()
            values.isExcludedFromBackup = false
            var mutableURL = file
            try mutableURL.setResourceValues(values)
        } else {
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: file.path)
        }
        let reader = backup ? repository : ProtectedLocalBillingSignatureRepository(
            access: BillingAssetAccess(principalID: "private-principal") {
                try await fixture.permit.validate()
            },
            directory: fixture.directory
        )
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await reader.loadSignature()
        }
    }

    @Test("A symbolic link at the private root is rejected without touching its target")
    func symbolicRoot() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let target = fixture.base.appending(path: "target", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: fixture.directory, withDestinationURL: target)
        let repository = fixture.repository()
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await repository.loadSignature()
        }
        let bytes = try signatureImage(type: .png)
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await repository.importSignature(bytes)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: target.path).isEmpty)
    }

    @Test("Oversized dimensions and multiple image frames are rejected")
    func imageLimits() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        let rejectedImages = [
            try signatureImage(type: .png, width: 4097, height: 1),
            try signatureImage(type: .png, width: 2049, height: 2048),
            try signatureImage(type: .gif, frameCount: 2)
        ]
        for bytes in rejectedImages {
            await #expect(throws: BillingAssetError.invalidSignature) {
                try await repository.importSignature(bytes)
            }
        }
        #expect(!FileManager.default.fileExists(atPath: fixture.directory.path))
    }

    @Test("Truncated recognized image formats cannot replace an accepted signature", arguments: [UTType.png, .jpeg])
    func truncatedImage(type: UTType) async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        let previous = try signatureImage(type: .png)
        try await repository.importSignature(previous)
        let complete = try signatureImage(type: type)
        let truncated = Data(complete.prefix(complete.count / 2))
        await #expect(throws: BillingAssetError.invalidSignature) {
            try await repository.importSignature(truncated)
        }
        #expect(try await repository.loadSignature() == previous)
    }

    @Test("Symbolic links at owned principal directories or files never expose their targets", arguments: [false, true])
    func symbolicOwnedItem(fileLink: Bool) async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let repository = fixture.repository()
        let previous = try signatureImage(type: .png)
        try await repository.importSignature(previous)
        let file = try fixture.cachedFile()
        let original = fileLink ? file : file.deletingLastPathComponent()
        let target = fixture.base.appending(path: "target")
        try FileManager.default.moveItem(at: original, to: target)
        try FileManager.default.createSymbolicLink(at: original, withDestinationURL: target)
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await repository.loadSignature()
        }
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await repository.importSignature(previous)
        }
        let image = fileLink ? target : target.appending(path: file.lastPathComponent)
        #expect(try Data(contentsOf: image) == previous)
    }

    @Test("Private imports reject bundle directories before creating resources")
    func privateBundleLocation() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let bundleDirectory = fixture.base.appending(path: "synthetic.bundle", directoryHint: .isDirectory)
        let repository = ProtectedLocalBillingSignatureRepository(
            access: BillingAssetAccess(principalID: "private-principal") {
                try await fixture.permit.validate()
            },
            directory: bundleDirectory,
            verifyFileProtection: { _ in }
        )
        let image = try signatureImage(type: .png)
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await repository.importSignature(image)
        }
        #expect(!FileManager.default.fileExists(atPath: bundleDirectory.path))
    }
}

private struct SignatureFixture {
    let base: URL
    let directory: URL
    let permit = SignaturePermit()


    func repository(principal: String = "private-principal") -> ProtectedLocalBillingSignatureRepository {
        ProtectedLocalBillingSignatureRepository(
            access: BillingAssetAccess(principalID: principal) {
                try await permit.validate()
            },
            directory: directory,
            // Simulator reports no protection class. This double tests only the surrounding real pipeline.
            verifyFileProtection: { _ in }
        )
    }

    func cachedFile() throws -> URL {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let principalDirectory = try #require(files.first)
        return try #require(FileManager.default.contentsOfDirectory(
            at: principalDirectory,
            includingPropertiesForKeys: nil
        ).first { !$0.lastPathComponent.hasPrefix(".") })
    }

    func remove() {
        try? FileManager.default.removeItem(at: base)
    }
}

private extension SignatureFixture {
    init() throws {
        base = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        directory = base.appending(path: "private-assets", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: false)
    }
}

private actor SignaturePermit {
    private var isValid = true
    private var calls = 0
    private var blockedCall: Int?
    private var releaseContinuation: CheckedContinuation<Void, Never>?
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []

    func validate() async throws {
        guard isValid else { throw BillingAssetError.unauthorized }
        calls += 1
        if calls == blockedCall {
            await withCheckedContinuation { continuation in
                releaseContinuation = continuation
                blockedWaiters.forEach {
                    $0.resume()
                }
                blockedWaiters.removeAll()
            }
        }
        guard isValid else { throw BillingAssetError.unauthorized }
    }

    func blockSecondNextValidation() {
        blockedCall = calls + 2
    }
    func revoke() {
        isValid = false
    }
    func revokeAndRelease() {
        revoke()
        release()
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }

    func waitUntilBlocked() async {
        guard releaseContinuation == nil else { return }
        await withCheckedContinuation {
            blockedWaiters.append($0)
        }
    }
}

private func signatureImage(
    type: UTType,
    width: Int = 16,
    height: Int = 8,
    frameCount: Int = 1
) throws -> Data {
    let context = try #require(CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    context.setFillColor(CGColor(
        red: 0.2,
        green: 0.3,
        blue: 0.4,
        alpha: 1
    ))
    context.fill(CGRect(
        x: 0,
        y: 0,
        width: width,
        height: height
    ))
    let image = try #require(context.makeImage())
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(
        data,
        type.identifier as CFString,
        frameCount,
        nil
    ))
    for _ in 0..<frameCount {
        CGImageDestinationAddImage(destination, image, nil)
    }
    try #require(CGImageDestinationFinalize(destination))
    return data as Data
}

extension BillingBusinessSignatureRepositoryTests {
    @Test("A replacement failure after moving the original preserves it through reopening")
    func movedOriginalRecovery() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let previous = try signatureImage(type: .png)
        try await fixture.repository().importSignature(previous)
        let replacement = try signatureImage(type: .jpeg)
        let failing = fixture.failingRepository()
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await failing.importSignature(replacement)
        }
        #expect(try await fixture.repository().loadSignature() == previous)
        let file = try fixture.cachedFile()
        #expect(try FileManager.default.contentsOfDirectory(atPath: file.deletingLastPathComponent().path).count == 1)
    }

    @Test("A failed rollback retains authoritative recovery across reopening and a later import")
    func failedRollbackRecovery() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let previous = try signatureImage(type: .png)
        try await fixture.repository().importSignature(previous)
        let replacement = try signatureImage(type: .jpeg)
        let failing = fixture.failingRepository(rejectRestoration: true)
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await failing.importSignature(replacement)
        }
        #expect(try await failing.loadSignature() == previous)
        let file = try fixture.cachedFile()
        let backup = file.deletingLastPathComponent().appending(path: ".previous-signature")
        #expect(try Data(contentsOf: backup) == previous)
        #expect(try backup.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
        try FileManager.default.removeItem(at: fixture.base.appending(path: "reject-restoration"))
        try await fixture.repository().importSignature(replacement)
        #expect(try await fixture.repository().loadSignature() == replacement)
        #expect(!FileManager.default.fileExists(atPath: backup.path))
    }

    @Test("A later failing writer preserves the version published by another repository")
    func twoRepositoriesPreserveLatest() async throws {
        let fixture = try SignatureFixture()
        defer {
            fixture.remove()
        }
        let original = try signatureImage(type: .png)
        try await fixture.repository().importSignature(original)
        await fixture.permit.blockSecondNextValidation()
        let first = fixture.failingRepository()
        let rejected = try signatureImage(type: .png, width: 8, height: 8)
        let operation = Task {
            try await first.importSignature(rejected)
        }
        await fixture.permit.waitUntilBlocked()
        let second = fixture.repository()
        let current = try signatureImage(type: .jpeg)
        try await second.importSignature(current)
        await fixture.permit.release()
        await #expect(throws: BillingAssetError.signatureUnavailable) {
            try await operation.value
        }
        #expect(try await fixture.repository().loadSignature() == current)
    }
}

private extension SignatureFixture {
    func failingRepository(rejectRestoration: Bool = false) -> ProtectedLocalBillingSignatureRepository {
        let marker = base.appending(path: "reject-restoration")
        let displaced = base.appending(path: "original-displaced-by-replacement")
        return ProtectedLocalBillingSignatureRepository(
            access: BillingAssetAccess(principalID: "private-principal") {
                try await permit.validate()
            },
            directory: directory,
            verifyFileProtection: { url in
                if rejectRestoration, url.lastPathComponent == "business-signature",
                   FileManager.default.fileExists(atPath: marker.path) {
                    throw BillingAssetError.signatureUnavailable
                }
            },
            replaceFile: { original, _ in
                try FileManager.default.moveItem(at: original, to: displaced)
                if rejectRestoration {
                    try Data().write(to: marker)
                }
                throw NSError(
                    domain: NSCocoaErrorDomain,
                    code: NSFileWriteUnknownError,
                    userInfo: ["NSFileOriginalItemLocationKey": displaced]
                )
            }
        )
    }
}
