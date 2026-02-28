import XCTest
@testable import BrewNotifierCore

final class DailyScheduleTests: XCTestCase {

    // MARK: - secondsUntilNextFire

    func testNextFireIsSameDayWhenHourIsInFuture() {
        // 08:00 now, target 09:00 → 3600 seconds
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "UTC")!

        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1
        comps.hour = 8; comps.minute = 0; comps.second = 0
        let now = cal.date(from: comps)!

        let seconds = DailySchedule.secondsUntilNextFire(targetHour: 9, from: now, calendar: cal)
        XCTAssertEqual(seconds, 3600, accuracy: 1)
    }

    func testNextFireIsNextDayWhenHourHasPassed() {
        // 10:00 now, target 09:00 → ~23 hours from now
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "UTC")!

        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1
        comps.hour = 10; comps.minute = 0; comps.second = 0
        let now = cal.date(from: comps)!

        let seconds = DailySchedule.secondsUntilNextFire(targetHour: 9, from: now, calendar: cal)
        let expected: TimeInterval = 23 * 3600
        XCTAssertEqual(seconds, expected, accuracy: 1)
    }

    func testNextFireIsCorrectWhenExactlyAtTargetHour() {
        // 09:00:00 now, target 09:00 → fires next day (24h)
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "UTC")!

        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1
        comps.hour = 9; comps.minute = 0; comps.second = 0
        let now = cal.date(from: comps)!

        let seconds = DailySchedule.secondsUntilNextFire(targetHour: 9, from: now, calendar: cal)
        let expected: TimeInterval = 24 * 3600
        XCTAssertEqual(seconds, expected, accuracy: 1)
    }

    func testNextFireHandlesMidnight() {
        // 23:30 now, target 00:00 → 30 minutes
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "UTC")!

        var comps = DateComponents()
        comps.year = 2026; comps.month = 1; comps.day = 1
        comps.hour = 23; comps.minute = 30; comps.second = 0
        let now = cal.date(from: comps)!

        let seconds = DailySchedule.secondsUntilNextFire(targetHour: 0, from: now, calendar: cal)
        XCTAssertEqual(seconds, 30 * 60, accuracy: 1)
    }
}
