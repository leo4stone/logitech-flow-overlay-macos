import XCTest
@testable import LogitechFlowOverlay

final class OverlaySettingsTests: XCTestCase {
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

    func testLowerValueReducesTintAndBlurStrength() {
        let settings = OverlaySettings(
            transparency: 0.42,
            message: "Message"
        )

        XCTAssertEqual(settings.tintAlpha, 0.42, accuracy: 0.0001)
        XCTAssertEqual(settings.blurAlpha, 0.42, accuracy: 0.0001)

        let clearerSettings = OverlaySettings(
            transparency: 0.10,
            message: "Message"
        )
        XCTAssertLessThan(clearerSettings.tintAlpha, settings.tintAlpha)
        XCTAssertLessThan(clearerSettings.blurAlpha, settings.blurAlpha)
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
