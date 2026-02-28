import XCTest
@testable import BrewNotifierCore

final class UpgradeServiceTests: XCTestCase {

    func testUpgradeThrowsWhenBrewNotFound() async throws {
        let service = UpgradeService(brewPathOverride: "/nonexistent/brew")
        do {
            try await service.upgrade(package: "git")
            XCTFail("Expected brewNotFound")
        } catch UpgradeServiceError.brewNotFound {
            // pass
        }
    }

    func testUpgradeSucceedsWithStub() async throws {
        let service = UpgradeService(stubbedExitCode: 0, stubbedStderr: "")
        try await service.upgrade(package: "git")  // should not throw
    }

    func testUpgradeFailsWithNonZeroExit() async throws {
        let service = UpgradeService(stubbedExitCode: 1, stubbedStderr: "Error: git not installed")
        do {
            try await service.upgrade(package: "git")
            XCTFail("Expected executionFailed")
        } catch UpgradeServiceError.executionFailed(let msg) {
            XCTAssertTrue(msg.contains("git not installed"))
        }
    }

    func testErrorDescription() {
        XCTAssertNotNil(UpgradeServiceError.brewNotFound.errorDescription)
        XCTAssertNotNil(UpgradeServiceError.executionFailed("x").errorDescription)
    }

    func testUpgradeWithProgressSucceedsWithStub() async throws {
        let service = UpgradeService(stubbedExitCode: 0)
        var lines: [String] = []
        try await service.upgradeWithProgress(package: "git") { line in
            lines.append(line)
        }
        // Stubbed path — just verify no throw
    }

    func testUpgradeAllWithProgressSucceedsWithStub() async throws {
        let service = UpgradeService(stubbedExitCode: 0)
        try await service.upgradeAllWithProgress { _ in }
    }
}
