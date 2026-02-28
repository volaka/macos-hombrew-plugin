import Foundation

public enum BrewServiceError: Error, LocalizedError {
    case brewNotFound
    case executionFailed(String)
    case parseError(Error)

    public var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew not found. Please install it at https://brew.sh"
        case .executionFailed(let msg):
            return "brew failed: \(msg)"
        case .parseError(let err):
            return "Failed to parse brew output: \(err.localizedDescription)"
        }
    }
}

public final class BrewService {
    private static let brewPaths = [
        "/opt/homebrew/bin/brew",  // Apple Silicon
        "/usr/local/bin/brew",     // Intel
    ]

    // Overrides for testing
    private let brewPathOverride: String?
    private let stubbedOutput: Data?

    public init(brewPathOverride: String? = nil, stubbedOutput: Data? = nil) {
        self.brewPathOverride = brewPathOverride
        self.stubbedOutput = stubbedOutput
    }

    public static func brewPath() -> String? {
        brewPaths.first { FileManager.default.fileExists(atPath: $0) }
    }

    private func resolvedBrewPath() -> String? {
        if let override = brewPathOverride {
            return FileManager.default.fileExists(atPath: override) ? override : nil
        }
        return BrewService.brewPath()
    }

    /// Runs `brew outdated --json=v2` and returns parsed results.
    public func fetchOutdated() async throws -> (formulae: [BrewPackage], casks: [BrewCask]) {
        try await fetchOutdatedWithProgress(progressHandler: nil)
    }

    /// Same as fetchOutdated but streams stderr lines to progressHandler as they arrive.
    public func fetchOutdatedWithProgress(
        progressHandler: ((String) -> Void)?
    ) async throws -> (formulae: [BrewPackage], casks: [BrewCask]) {
        if let stubbed = stubbedOutput {
            return try parse(stubbed)
        }

        guard let brew = resolvedBrewPath() else {
            throw BrewServiceError.brewNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: brew)
                    process.arguments = ["outdated", "--json=v2"]

                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe

                    if let handler = progressHandler {
                        errorPipe.fileHandleForReading.readabilityHandler = { handle in
                            let data = handle.availableData
                            guard !data.isEmpty,
                                  let text = String(data: data, encoding: .utf8) else { return }
                            for line in text.components(separatedBy: "\n") where !line.isEmpty {
                                handler(line)
                            }
                        }
                    }

                    try process.run()
                    process.waitUntilExit()

                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

                    if process.terminationStatus != 0 {
                        let errMsg = String(
                            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                            encoding: .utf8
                        ) ?? "unknown"
                        continuation.resume(throwing: BrewServiceError.executionFailed(errMsg))
                        return
                    }

                    do {
                        let result = try self.parse(outputData)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func parse(_ data: Data) throws -> (formulae: [BrewPackage], casks: [BrewCask]) {
        do {
            let response = try JSONDecoder().decode(BrewOutdatedResponse.self, from: data)
            return (response.formulae, response.casks)
        } catch {
            throw BrewServiceError.parseError(error)
        }
    }
}
