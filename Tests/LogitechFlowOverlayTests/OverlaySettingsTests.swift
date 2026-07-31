import XCTest
@testable import LogitechFlowOverlay

final class OverlaySettingsTests: XCTestCase {
    func testProductDefaults() {
        XCTAssertEqual(OverlaySettings.defaultTransparency, 0.20)
        XCTAssertEqual(OverlaySettings.defaultGlassIntensity, 0.80)
    }

    func testTransparencyIsClampedToSupportedRange() {
        XCTAssertEqual(
            OverlaySettings(
                transparency: -1,
                message: "Message"
            ).transparency,
            OverlaySettings.minimumTransparency
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 2,
                message: "Message"
            ).transparency,
            OverlaySettings.maximumTransparency
        )
    }

    func testTransparencyControlsOnlyTintAlpha() {
        let settings = OverlaySettings(
            transparency: 0.42,
            glassIntensity: 0.75,
            message: "Message"
        )

        XCTAssertEqual(settings.tintAlpha, 0.42, accuracy: 0.0001)

        let lighterTint = OverlaySettings(
            transparency: 0.10,
            glassIntensity: 0.75,
            message: "Message"
        )
        XCTAssertLessThan(lighterTint.tintAlpha, settings.tintAlpha)
        XCTAssertEqual(
            lighterTint.glassIntensity,
            settings.glassIntensity,
            accuracy: 0.0001
        )
    }

    func testGlassIntensityIsClampedToSupportedRange() {
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: -1,
                message: "Message"
            ).glassIntensity,
            OverlaySettings.minimumGlassIntensity
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: 2,
                message: "Message"
            ).glassIntensity,
            OverlaySettings.maximumGlassIntensity
        )
    }

    func testGlassIntensityMapsVisibleRangeAcrossFullSlider() {
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: 0,
                message: "Message"
            ).glassMaskAlpha,
            0.60,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: 0.25,
                message: "Message"
            ).glassMaskAlpha,
            0.795,
            accuracy: 0.001
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: 0.5,
                message: "Message"
            ).glassMaskAlpha,
            0.92,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: 0.75,
                message: "Message"
            ).glassMaskAlpha,
            0.984,
            accuracy: 0.001
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                glassIntensity: 1,
                message: "Message"
            ).glassMaskAlpha,
            1,
            accuracy: 0.0001
        )
    }

    func testMessageIsTrimmedAndFallsBackWhenEmpty() {
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                message: "  Custom message \n",
                defaultMessage: "Default"
            ).message,
            "Custom message"
        )
        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                message: " \n ",
                defaultMessage: "Default"
            ).message,
            "Default"
        )
    }

    func testMessageLengthIsLimited() {
        let message = String(
            repeating: "a",
            count: OverlaySettings.maximumMessageLength + 10
        )

        XCTAssertEqual(
            OverlaySettings(
                transparency: 0.42,
                message: message
            ).message.count,
            OverlaySettings.maximumMessageLength
        )
    }
}
