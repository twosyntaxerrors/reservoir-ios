import XCTest
@testable import Reservoir

final class ReservoirTests: XCTestCase {

    func testFillFractionStartsAtZero() {
        XCTAssertEqual(fillFraction(for: 0), 0)
        XCTAssertEqual(fillFraction(for: -4), 0)
        XCTAssertGreaterThan(fillFraction(for: 1), 0)
    }

    @MainActor
    func testResetClearsAllTrackedProgress() {
        let suiteName = "ReservoirTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ReservoirStore(defaults: defaults)
        store.previewAdvanceOneDay()
        store.previewAdvanceOneDay()

        XCTAssertEqual(store.currentStreak, 2)
        XCTAssertEqual(store.longestStreak, 2)
        XCTAssertEqual(store.totalRetentionDays, 2)
        XCTAssertNotNil(store.lastCheckIn)

        store.reset()

        XCTAssertEqual(store.currentStreak, 0)
        XCTAssertEqual(store.longestStreak, 0)
        XCTAssertEqual(store.totalRetentionDays, 0)
        XCTAssertEqual(store.relapseCount, 0)
        XCTAssertNil(store.lastCheckIn)
        XCTAssertEqual(store.selectedVessel, .apprentice)
        XCTAssertEqual(store.fillProgress, 0)
    }
}
