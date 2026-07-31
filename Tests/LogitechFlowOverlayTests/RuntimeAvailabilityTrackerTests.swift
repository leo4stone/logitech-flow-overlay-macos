import XCTest
@testable import LogitechFlowOverlay

final class RuntimeAvailabilityTrackerTests: XCTestCase {
    func testInitialAvailabilityIsReportedImmediately() {
        var tracker = RuntimeAvailabilityTracker(
            unavailabilityGracePeriod: 2
        )

        XCTAssertEqual(
            tracker.observe(rawIsAvailable: true, at: 10),
            true
        )
        XCTAssertEqual(tracker.isAvailable, true)
    }

    func testTransientUnavailableSampleDoesNotChangeStableState() {
        var tracker = RuntimeAvailabilityTracker(
            unavailabilityGracePeriod: 2
        )
        _ = tracker.observe(rawIsAvailable: true, at: 10)

        XCTAssertNil(tracker.observe(rawIsAvailable: false, at: 20))
        XCTAssertTrue(tracker.isUnavailabilityPending)
        XCTAssertEqual(tracker.isAvailable, true)

        XCTAssertNil(tracker.observe(rawIsAvailable: true, at: 20.5))
        XCTAssertFalse(tracker.isUnavailabilityPending)
        XCTAssertEqual(tracker.isAvailable, true)
    }

    func testContinuousUnavailabilityChangesStateAfterGracePeriod() {
        var tracker = RuntimeAvailabilityTracker(
            unavailabilityGracePeriod: 2
        )
        _ = tracker.observe(rawIsAvailable: true, at: 10)

        XCTAssertNil(tracker.observe(rawIsAvailable: false, at: 20))
        XCTAssertNil(tracker.observe(rawIsAvailable: false, at: 21.9))
        XCTAssertEqual(
            tracker.observe(rawIsAvailable: false, at: 22),
            false
        )
        XCTAssertEqual(tracker.isAvailable, false)
    }

    func testAvailabilityRecoversImmediately() {
        var tracker = RuntimeAvailabilityTracker(
            unavailabilityGracePeriod: 2
        )
        XCTAssertEqual(
            tracker.observe(rawIsAvailable: false, at: 10),
            false
        )

        XCTAssertEqual(
            tracker.observe(rawIsAvailable: true, at: 11),
            true
        )
        XCTAssertEqual(tracker.isAvailable, true)
    }
}
