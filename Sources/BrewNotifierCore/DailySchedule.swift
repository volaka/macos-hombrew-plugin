import Foundation

public enum DailySchedule {
    /// Returns the number of seconds from `now` until the next occurrence of `targetHour:00:00`.
    /// If `now` is exactly at `targetHour`, the next fire is 24 hours away.
    public static func secondsUntilNextFire(
        targetHour: Int,
        from now: Date = Date(),
        calendar: Calendar = .current
    ) -> TimeInterval {
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = targetHour
        comps.minute = 0
        comps.second = 0

        guard var fireDate = calendar.date(from: comps) else { return 24 * 3600 }

        if fireDate <= now {
            fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
        }

        return fireDate.timeIntervalSince(now)
    }
}
