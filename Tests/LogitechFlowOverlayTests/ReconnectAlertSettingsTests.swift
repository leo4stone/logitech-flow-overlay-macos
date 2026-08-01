import XCTest
@testable import LogitechFlowOverlay

final class ReconnectAlertSettingsTests: XCTestCase {
    func testProductDefaults() {
        XCTAssertTrue(ReconnectAlertSettings.defaultEnabled)
        XCTAssertEqual(ReconnectAlertSettings.defaultDimOpacity, 0.50)
        XCTAssertEqual(ReconnectAlertSettings.defaultDuration, 2.0)
        XCTAssertEqual(ReconnectAlertSettings.defaultRadius, 100)
        XCTAssertEqual(ReconnectAlertSettings.defaultFeather, 0.04)
        XCTAssertEqual(
            ReconnectAlertSettings.defaultSpotlightColor,
            ReconnectSpotlightColor(
                red: 1,
                green: 1,
                blue: 1,
                alpha: 0.20
            )
        )
    }

    func testDimOpacityIsClampedToSupportedRange() {
        XCTAssertEqual(
            makeSettings(dimOpacity: -1).dimOpacity,
            ReconnectAlertSettings.minimumDimOpacity
        )
        XCTAssertEqual(
            makeSettings(dimOpacity: 2).dimOpacity,
            ReconnectAlertSettings.maximumDimOpacity
        )
    }

    func testDurationIsClampedToSupportedRange() {
        XCTAssertEqual(
            makeSettings(duration: 0).duration,
            ReconnectAlertSettings.minimumDuration
        )
        XCTAssertEqual(
            makeSettings(duration: 20).duration,
            ReconnectAlertSettings.maximumDuration
        )
    }

    func testRadiusIsClampedToSupportedRange() {
        XCTAssertEqual(
            makeSettings(radius: 1).radius,
            ReconnectAlertSettings.minimumRadius
        )
        XCTAssertEqual(
            makeSettings(radius: 1_000).radius,
            ReconnectAlertSettings.maximumRadius
        )
    }

    func testFeatherIsClampedToSupportedRange() {
        XCTAssertEqual(
            makeSettings(feather: -1).feather,
            ReconnectAlertSettings.minimumFeather
        )
        XCTAssertEqual(
            makeSettings(feather: 2).feather,
            ReconnectAlertSettings.maximumFeather
        )
    }

    func testSpotlightColorComponentsAreClamped() {
        XCTAssertEqual(
            ReconnectSpotlightColor(
                red: -1,
                green: 2,
                blue: 0.5,
                alpha: 3
            ),
            ReconnectSpotlightColor(
                red: 0,
                green: 1,
                blue: 0.5,
                alpha: 1
            )
        )
    }

    private func makeSettings(
        dimOpacity: Double = ReconnectAlertSettings.defaultDimOpacity,
        duration: Double = ReconnectAlertSettings.defaultDuration,
        radius: Double = ReconnectAlertSettings.defaultRadius,
        feather: Double = ReconnectAlertSettings.defaultFeather,
        spotlightColor: ReconnectSpotlightColor =
            ReconnectAlertSettings.defaultSpotlightColor
    ) -> ReconnectAlertSettings {
        ReconnectAlertSettings(
            isEnabled: true,
            dimOpacity: dimOpacity,
            duration: duration,
            radius: radius,
            feather: feather,
            spotlightColor: spotlightColor
        )
    }
}
