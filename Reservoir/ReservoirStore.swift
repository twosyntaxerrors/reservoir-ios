import Combine
import SwiftUI

@MainActor
final class ReservoirStore: ObservableObject {
    @Published private(set) var currentStreak: Int
    @Published private(set) var longestStreak: Int
    @Published private(set) var totalRetentionDays: Int
    @Published private(set) var lastCheckIn: Date?
    @Published var selectedVessel: VesselSkin
    @Published private(set) var relapseCount: Int

    private let defaults: UserDefaults
    private let calendar = Calendar.current

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currentStreak = defaults.integer(forKey: Keys.currentStreak)
        longestStreak = defaults.integer(forKey: Keys.longestStreak)
        totalRetentionDays = defaults.integer(forKey: Keys.totalRetentionDays)
        lastCheckIn = defaults.object(forKey: Keys.lastCheckIn) as? Date
        relapseCount = defaults.integer(forKey: Keys.relapseCount)
        selectedVessel = VesselSkin(rawValue: defaults.string(forKey: Keys.selectedVessel) ?? VesselSkin.apprentice.rawValue) ?? .apprentice
        if !isUnlocked(selectedVessel) { selectedVessel = .apprentice }
    }

    var canCheckInToday: Bool {
        guard let lastCheckIn else { return true }
        return !calendar.isDateInToday(lastCheckIn)
    }

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
        case 365...: return "Cosmic identity unlocked"
        case 180...: return "Energy arcs forming"
        case 90...: return "Internal current active"
        case 30...: return "Lunar glow stabilized"
        case 7...: return "Particles awakened"
        default: return "First light gathering"
        }
    }

    func checkInToday() {
        guard canCheckInToday else { return }
        currentStreak += 1
        longestStreak = max(longestStreak, currentStreak)
        totalRetentionDays += 1
        lastCheckIn = Date()
        persist()
    }

    func previewAdvanceOneDay() {
        currentStreak += 1
        longestStreak = max(longestStreak, currentStreak)
        totalRetentionDays += 1
        lastCheckIn = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        persist()
    }

    /// Full reset: returns every tracked value to zero and starts a brand-new journey.
    func reset() {
        currentStreak = 0
        longestStreak = 0
        totalRetentionDays = 0
        lastCheckIn = nil
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
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)
        defaults.set(totalRetentionDays, forKey: Keys.totalRetentionDays)
        defaults.set(lastCheckIn, forKey: Keys.lastCheckIn)
        defaults.set(relapseCount, forKey: Keys.relapseCount)
        defaults.set(selectedVessel.rawValue, forKey: Keys.selectedVessel)
    }
}

private enum Keys {
    static let currentStreak = "reservoir.currentStreak"
    static let longestStreak = "reservoir.longestStreak"
    static let totalRetentionDays = "reservoir.totalRetentionDays"
    static let lastCheckIn = "reservoir.lastCheckIn"
    static let selectedVessel = "reservoir.selectedVessel"
    static let relapseCount = "reservoir.relapseCount"
}
