import XCTest
@testable import BrewNotifierCore

final class AppSettingsTests: XCTestCase {

    var defaults: UserDefaults!
    var settings: AppSettings!

    override func setUp() {
        super.setUp()
        // Use an isolated suite so tests don't pollute real UserDefaults
        defaults = UserDefaults(suiteName: "BrewNotifierTests-\(UUID().uuidString)")!
        settings = AppSettings(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.description)
        super.tearDown()
    }

    // MARK: - Defaults

    func testDefaultCheckIntervalIsOneHour() {
        XCTAssertEqual(settings.checkIntervalMinutes, 60)
    }

    func testDefaultScheduleModeIsInterval() {
        XCTAssertEqual(settings.scheduleMode, .interval)
    }

    func testDefaultStartHourIsNine() {
        XCTAssertEqual(settings.dailyStartHour, 9)
    }

    func testDefaultIgnoredPackagesIsEmpty() {
        XCTAssertTrue(settings.ignoredPackages.isEmpty)
    }

    // MARK: - Persistence

    func testCheckIntervalPersists() {
        settings.checkIntervalMinutes = 30
        let settings2 = AppSettings(defaults: defaults)
        XCTAssertEqual(settings2.checkIntervalMinutes, 30)
    }

    func testScheduleModePersists() {
        settings.scheduleMode = .daily
        let settings2 = AppSettings(defaults: defaults)
        XCTAssertEqual(settings2.scheduleMode, .daily)
    }

    func testDailyStartHourPersists() {
        settings.dailyStartHour = 14
        let settings2 = AppSettings(defaults: defaults)
        XCTAssertEqual(settings2.dailyStartHour, 14)
    }

    func testIgnoredPackagesPersist() {
        settings.ignoredPackages = ["git", "curl"]
        let settings2 = AppSettings(defaults: defaults)
        XCTAssertEqual(settings2.ignoredPackages, ["git", "curl"])
    }
}
