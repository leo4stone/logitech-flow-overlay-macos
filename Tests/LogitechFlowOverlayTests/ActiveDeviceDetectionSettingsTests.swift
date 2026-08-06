import XCTest
@testable import LogitechFlowOverlay

final class ActiveDeviceDetectionSettingsTests: XCTestCase {
    func testProductDefaultsEnableEveryEdge() {
        XCTAssertTrue(ActiveDeviceDetectionSettings.defaultEnabled)
        XCTAssertEqual(
            ActiveDeviceDetectionSettings.defaultTriggerEdges,
            .all
        )
    }

    func testUnknownStoredBitsAreDiscarded() {
        let settings = ActiveDeviceDetectionSettings(
            isEnabled: true,
            triggerEdges: FlowTriggerEdges(
                rawValue: FlowTriggerEdges.left.rawValue | (1 << 12)
            )
        )

        XCTAssertEqual(settings.triggerEdges, .left)
    }

    func testNoTriggerEdgeIsRepresentable() {
        let settings = ActiveDeviceDetectionSettings(
            isEnabled: true,
            triggerEdges: []
        )

        XCTAssertTrue(settings.triggerEdges.isEmpty)
    }
}
