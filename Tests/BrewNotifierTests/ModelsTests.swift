import XCTest
@testable import BrewNotifierCore

final class ModelsTests: XCTestCase {

    // MARK: - BrewPackage

    func testBrewPackageDecoding() throws {
        let json = """
        {
            "name": "git",
            "installed_versions": ["2.43.0"],
            "current_version": "2.44.0",
            "pinned": false,
            "pinned_version": null
        }
        """.data(using: .utf8)!

        let pkg = try JSONDecoder().decode(BrewPackage.self, from: json)

        XCTAssertEqual(pkg.name, "git")
        XCTAssertEqual(pkg.installedVersions, ["2.43.0"])
        XCTAssertEqual(pkg.currentVersion, "2.44.0")
        XCTAssertEqual(pkg.id, "git")
    }

    func testBrewPackageMultipleInstalledVersions() throws {
        let json = """
        {
            "name": "python@3.13",
            "installed_versions": ["3.13.0", "3.13.1"],
            "current_version": "3.13.2",
            "pinned": false,
            "pinned_version": null
        }
        """.data(using: .utf8)!

        let pkg = try JSONDecoder().decode(BrewPackage.self, from: json)
        XCTAssertEqual(pkg.installedVersions.count, 2)
    }

    // MARK: - BrewCask

    func testBrewCaskDecoding() throws {
        // Real brew output: installed_versions is an ARRAY, not a string
        let json = """
        {
            "name": "chromedriver",
            "installed_versions": ["143.0.7499.192"],
            "current_version": "146.0.7680.31"
        }
        """.data(using: .utf8)!

        let cask = try JSONDecoder().decode(BrewCask.self, from: json)

        XCTAssertEqual(cask.name, "chromedriver")
        XCTAssertEqual(cask.installedVersions, ["143.0.7499.192"])
        XCTAssertEqual(cask.currentVersion, "146.0.7680.31")
        XCTAssertEqual(cask.id, "chromedriver")
    }

    // MARK: - BrewOutdatedResponse

    func testFullResponseDecoding() throws {
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

        let response = try JSONDecoder().decode(BrewOutdatedResponse.self, from: json)

        XCTAssertEqual(response.formulae.count, 1)
        XCTAssertEqual(response.formulae[0].name, "git")
        XCTAssertEqual(response.casks.count, 1)
        XCTAssertEqual(response.casks[0].name, "firefox")
    }

    func testEmptyResponse() throws {
        let json = """
        {"formulae": [], "casks": []}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(BrewOutdatedResponse.self, from: json)
        XCTAssertTrue(response.formulae.isEmpty)
        XCTAssertTrue(response.casks.isEmpty)
    }
}
