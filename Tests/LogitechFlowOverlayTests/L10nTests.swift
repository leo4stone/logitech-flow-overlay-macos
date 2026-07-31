import XCTest
@testable import LogitechFlowOverlay

final class L10nTests: XCTestCase {
    func testChineseIsSelectedForChinesePrimaryLanguage() {
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: ["zh-Hans-CN", "en-US"]),
            .chinese
        )
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: ["zh-Hant-TW"]),
            .chinese
        )
    }

    func testEnglishIsSelectedForEveryOtherPrimaryLanguage() {
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: ["en-US", "zh-Hans-CN"]),
            .english
        )
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: ["ja-JP"]),
            .english
        )
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: []),
            .english
        )
    }
}
