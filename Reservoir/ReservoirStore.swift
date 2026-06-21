import Combine
import SwiftUI

@MainActor
final class ReservoirStore: ObservableObject {
    /// Source of truth: the set of calendar days (normalized to start-of-day) that were checked in.
    @Published private(set) var checkInDays: Set<Date>
    @Published var selectedVessel: VesselSkin
    @Published private(set) var relapseCount: Int

    /// Floor that preserves a previously earned longest streak (e.g. migrated data),
    /// so vessel unlocks are never lost even if the full day history isn't reconstructable.
    private var longestStreakFloor: Int

    private let defaults: UserDefaults
    private let calendar = Calendar.current

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let cal = Calendar.current
        func key(_ date: Date) -> Date { cal.startOfDay(for: date) }

        relapseCount = defaults.integer(forKey: Keys.relapseCount)
        selectedVessel = VesselSkin(rawValue: defaults.string(forKey: Keys.selectedVessel) ?? VesselSkin.apprentice.rawValue) ?? .apprentice

        if let stored = defaults.array(forKey: Keys.checkInDays) as? [Double] {
            checkInDays = Set(stored.map { key(Date(timeIntervalSince1970: $0)) })
            longestStreakFloor = defaults.integer(forKey: Keys.longestStreakFloor)
        } else {
            // Migrate from the legacy counter model: rebuild the current streak as a
            // run of consecutive days ending at the last recorded check-in (or today).
            let legacyStreak = defaults.integer(forKey: Keys.currentStreak)
            let legacyLast = defaults.object(forKey: Keys.lastCheckIn) as? Date
            var set = Set<Date>()
            if legacyStreak > 0 {
                let end = key(legacyLast ?? Date())
                for offset in 0..<legacyStreak {
                    if let day = cal.date(byAdding: .day, value: -offset, to: end) { set.insert(day) }
                }
            }
            checkInDays = set
            longestStreakFloor = max(defaults.integer(forKey: Keys.longestStreak), legacyStreak)
        }

        if !isUnlocked(selectedVessel) { selectedVessel = .apprentice }
    }

    // MARK: - Derived values

    private func dayKey(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    var lastCheckIn: Date? { checkInDays.max() }

    var totalRetentionDays: Int { checkInDays.count }

    /// Consecutive days ending today, or ending yesterday if today isn't logged yet
    /// (so the streak doesn't read as broken before today's check-in).
    var currentStreak: Int {
        let today = dayKey(Date())
        let anchor: Date
        if checkInDays.contains(today) {
            anchor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), checkInDays.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }
        var count = 0
        var cursor = anchor
        while checkInDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    private var computedLongestStreak: Int {
        guard !checkInDays.isEmpty else { return 0 }
        let sorted = checkInDays.sorted()
        var longest = 1
        var run = 1
        for index in 1..<sorted.count {
            if let next = calendar.date(byAdding: .day, value: 1, to: sorted[index - 1]),
               calendar.isDate(next, inSameDayAs: sorted[index]) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    var longestStreak: Int { max(longestStreakFloor, computedLongestStreak) }

    var fillProgress: Double { fillFraction(for: currentStreak) }
    var glowProgress: Double { glowStrength(for: currentStreak) }
    var primaryGlow: Color { selectedVessel.glowColor }

    var nextAchievementTitle: String {
        nextAchievement?.title ?? "Legendary Reservoir"
    }

    var nextAchievement: Achievement? {
        Achievement.all.first(where: { $0.days > currentStreak })
    }

    /// Days remaining until the next achievement unlocks.
    var daysUntilNextAchievement: Int {
        guard let next = nextAchievement else { return 0 }
        return max(0, next.days - currentStreak)
    }

    /// Fractional progress (0...1) from the previously cleared milestone toward the next one.
    var achievementProgress: Double {
        guard let next = nextAchievement else { return 1 }
        let previousDays = Achievement.all.last(where: { $0.days <= currentStreak })?.days ?? 0
        let span = Double(next.days - previousDays)
        guard span > 0 else { return 1 }
        return min(1, max(0, Double(currentStreak - previousDays) / span))
    }

    var milestoneText: String {
        switch currentStreak {
        case 365...: return "The reservoir is full"
        case 180...: return "Deep measure held"
        case 90...: return "A season kept"
        case 30...: return "One month held"
        case 7...: return "One week held"
        default: return "First light gathering"
        }
    }

    /// The earliest date a check-in may be backfilled to.
    var earliestCheckInDate: Date {
        calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
    }

    // MARK: - Mutations

    var canCheckInToday: Bool { canCheckIn(on: Date()) }

    /// A day can be logged if it isn't in the future and hasn't already been logged.
    func canCheckIn(on date: Date) -> Bool {
        let key = dayKey(date)
        return key <= dayKey(Date()) && !checkInDays.contains(key)
    }

    func isCheckedIn(on date: Date) -> Bool {
        checkInDays.contains(dayKey(date))
    }

    /// Logs a retained day for the given date (today or any earlier day).
    func checkIn(on date: Date) {
        guard canCheckIn(on: date) else { return }
        checkInDays.insert(dayKey(date))
        longestStreakFloor = max(longestStreakFloor, computedLongestStreak)
        persist()
    }

    func checkInToday() { checkIn(on: Date()) }

    /// Number of not-yet-logged days from `date` through today (inclusive).
    func unloggedDaysThroughToday(from date: Date) -> Int {
        let today = dayKey(Date())
        var cursor = dayKey(date)
        guard cursor <= today else { return 0 }
        var count = 0
        while cursor <= today {
            if !checkInDays.contains(cursor) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return count
    }

    /// Catch-up: logs every day from `date` through today so the current
    /// streak reflects an unbroken run up to now.
    func checkInThroughToday(from date: Date) {
        let today = dayKey(Date())
        var cursor = dayKey(date)
        guard cursor <= today else { return }
        while cursor <= today {
            checkInDays.insert(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        longestStreakFloor = max(longestStreakFloor, computedLongestStreak)
        persist()
    }

    /// Removes a previously logged day.
    func removeCheckIn(on date: Date) {
        guard checkInDays.remove(dayKey(date)) != nil else { return }
        persist()
    }

    /// Test/preview helper: appends one more consecutive day to the current run.
    func previewAdvanceOneDay() {
        var cursor = dayKey(Date())
        while checkInDays.contains(cursor) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { return }
            cursor = previous
        }
        checkInDays.insert(cursor)
        longestStreakFloor = max(longestStreakFloor, computedLongestStreak)
        persist()
    }

    /// Full reset: returns every tracked value to zero and starts a brand-new journey.
    func reset() {
        checkInDays = []
        longestStreakFloor = 0
        relapseCount = 0
        selectedVessel = .apprentice
        persist()
    }

    func isUnlocked(_ vessel: VesselSkin) -> Bool {
        longestStreak >= vessel.unlockDays
    }

    func selectVessel(_ vessel: VesselSkin) {
        guard isUnlocked(vessel) else { return }
        selectedVessel = vessel
        persist()
    }

    private func persist() {
        defaults.set(checkInDays.map { $0.timeIntervalSince1970 }, forKey: Keys.checkInDays)
        defaults.set(longestStreakFloor, forKey: Keys.longestStreakFloor)
        defaults.set(relapseCount, forKey: Keys.relapseCount)
        defaults.set(selectedVessel.rawValue, forKey: Keys.selectedVessel)
    }
}

private enum Keys {
    static let checkInDays = "reservoir.checkInDays"
    static let longestStreakFloor = "reservoir.longestStreakFloor"
    static let selectedVessel = "reservoir.selectedVessel"
    static let relapseCount = "reservoir.relapseCount"
    // Legacy keys (read once for migration).
    static let currentStreak = "reservoir.currentStreak"
    static let longestStreak = "reservoir.longestStreak"
    static let lastCheckIn = "reservoir.lastCheckIn"
}
