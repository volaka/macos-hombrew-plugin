import Foundation

public enum UpgradeServiceError: Error, LocalizedError {
    case brewNotFound
    case executionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew not found. Please install it at https://brew.sh"
        case .executionFailed(let msg):
            return "Upgrade failed: \(msg)"
        }
    }
}

public final class UpgradeService {
    private let brewPathOverride: String?
    private let stubbedExitCode: Int32?
    private let stubbedStderr: String?

    public init(
        brewPathOverride: String? = nil,
        stubbedExitCode: Int32? = nil,
        stubbedStderr: String? = nil
    ) {
        self.brewPathOverride = brewPathOverride
        self.stubbedExitCode = stubbedExitCode
        self.stubbedStderr = stubbedStderr
    }

    private func resolvedBrewPath() -> String? {
        if let override = brewPathOverride {
            return FileManager.default.fileExists(atPath: override) ? override : nil
        }
        return BrewService.brewPath()
    }

    /// Runs `brew upgrade <package>` non-blockingly, streaming stdout+stderr to progressHandler.
    public func upgradeWithProgress(
        package: String,
        progressHandler: @escaping (String) -> Void
    ) async throws {
        if let exitCode = stubbedExitCode {
            if exitCode != 0 {
                throw UpgradeServiceError.executionFailed(stubbedStderr ?? "unknown")
            }
            return
        }
        try await runBrewWithProgress(arguments: ["upgrade", package], progressHandler: progressHandler)
    }

    /// Runs `brew upgrade` (all packages) non-blockingly, streaming stdout+stderr to progressHandler.
    public func upgradeAllWithProgress(
        progressHandler: @escaping (String) -> Void
    ) async throws {
        if let exitCode = stubbedExitCode {
            if exitCode != 0 {
                throw UpgradeServiceError.executionFailed(stubbedStderr ?? "unknown")
            }
            return
        }
        try await runBrewWithProgress(arguments: ["upgrade"], progressHandler: progressHandler)
    }

    private func runBrewWithProgress(
        arguments: [String],
        progressHandler: @escaping (String) -> Void
    ) async throws {
        guard let brew = resolvedBrewPath() else {
            throw UpgradeServiceError.brewNotFound
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global().async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: brew)
                    process.arguments = arguments

                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe

                    let handler = { (handle: FileHandle) in
                        let data = handle.availableData
                        guard !data.isEmpty,
                              let text = String(data: data, encoding: .utf8) else { return }
                        for line in text.components(separatedBy: "\n") where !line.isEmpty {
                            progressHandler(line)
                        }
                    }
                    outputPipe.fileHandleForReading.readabilityHandler = handler
                    errorPipe.fileHandleForReading.readabilityHandler = handler

                    try process.run()
                    process.waitUntilExit()

                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    if process.terminationStatus != 0 {
                        let errMsg = String(
                            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                            encoding: .utf8
                        ) ?? "unknown error"
                        continuation.resume(throwing: UpgradeServiceError.executionFailed(errMsg))
                        return
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func upgrade(package: String) async throws {
        if let exitCode = stubbedExitCode {
            if exitCode != 0 {
                throw UpgradeServiceError.executionFailed(stubbedStderr ?? "unknown")
            }
            return
        }

        guard let brew = resolvedBrewPath() else {
            throw UpgradeServiceError.brewNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: brew)
        process.arguments = ["upgrade", package]

        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errMsg = String(
                data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? "unknown error"
            throw UpgradeServiceError.executionFailed(errMsg)
        }
    }
}
