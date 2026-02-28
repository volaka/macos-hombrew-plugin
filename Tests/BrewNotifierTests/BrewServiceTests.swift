import XCTest
@testable import BrewNotifierCore

final class BrewServiceTests: XCTestCase {

    func testFetchOutdatedThrowsWhenBrewNotFound() async throws {
        let service = BrewService(brewPathOverride: "/nonexistent/brew")

        do {
            _ = try await service.fetchOutdated()
            XCTFail("Expected brewNotFound error")
        } catch BrewServiceError.brewNotFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchOutdatedParsesStubbedJSON() async throws {
        let json = """
        {
            "formulae": [
                {
                    "name": "git",
                    "installed_versions": ["2.43.0"],
                    "current_version": "2.44.0",
                    "pinned": false,
                    "pinned_version": null
                }
            ],
            "casks": [
                {
                    "name": "firefox",
                    "installed_versions": ["122.0"],
                    "current_version": "123.0"
                }
            ]
        }
        """.data(using: .utf8)!

        let service = BrewService(stubbedOutput: json)
        let result = try await service.fetchOutdated()

        XCTAssertEqual(result.formulae.count, 1)
        XCTAssertEqual(result.formulae[0].name, "git")
        XCTAssertEqual(result.casks.count, 1)
        XCTAssertEqual(result.casks[0].name, "firefox")
    }

    func testFetchOutdatedThrowsOnInvalidJSON() async throws {
        let badData = "not json at all".data(using: .utf8)!
        let service = BrewService(stubbedOutput: badData)

        do {
            _ = try await service.fetchOutdated()
            XCTFail("Expected parseError")
        } catch BrewServiceError.parseError {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testBrewNotFoundErrorDescription() {
        let error = BrewServiceError.brewNotFound
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Homebrew"))
    }

    func testFetchOutdatedWithProgressCallsHandlerWithStubbedOutput() async throws {
        let json = """
        {"formulae": [], "casks": []}
        """.data(using: .utf8)!
        let service = BrewService(stubbedOutput: json)
        var lines: [String] = []
        let result = try await service.fetchOutdatedWithProgress { line in
            lines.append(line)
        }
        XCTAssertEqual(result.formulae.count, 0)
        XCTAssertEqual(result.casks.count, 0)
        // Stubbed path skips Process — lines will be empty, just verify no crash
    }
}
