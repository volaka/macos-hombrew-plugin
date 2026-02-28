import Foundation
import Combine

public enum ScheduleMode: String {
    case interval
    case daily
}

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @Published public var checkIntervalMinutes: Int {
        didSet { defaults.set(checkIntervalMinutes, forKey: Keys.checkInterval) }
    }

    @Published public var scheduleMode: ScheduleMode {
        didSet { defaults.set(scheduleMode.rawValue, forKey: Keys.scheduleMode) }
    }

    @Published public var dailyStartHour: Int {
        didSet { defaults.set(dailyStartHour, forKey: Keys.dailyStartHour) }
    }

    @Published public var ignoredPackages: [String] {
        didSet { defaults.set(ignoredPackages, forKey: Keys.ignoredPackages) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let checkInterval = "checkIntervalMinutes"
        static let scheduleMode = "scheduleMode"
        static let dailyStartHour = "dailyStartHour"
        static let ignoredPackages = "ignoredPackages"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedInterval = defaults.integer(forKey: Keys.checkInterval)
        checkIntervalMinutes = storedInterval > 0 ? storedInterval : 60

        let storedMode = defaults.string(forKey: Keys.scheduleMode)
        scheduleMode = ScheduleMode(rawValue: storedMode ?? "") ?? .interval

        let storedHour = defaults.object(forKey: Keys.dailyStartHour) as? Int
        dailyStartHour = storedHour ?? 9

        ignoredPackages = defaults.stringArray(forKey: Keys.ignoredPackages) ?? []
    }
}
