import XCTest
@testable import LogitechFlowOverlay

final class LogiOptionsPlusRuntimeTests: XCTestCase {
    func testRecognizesMainApplication() {
        XCTAssertTrue(LogiOptionsPlusRuntime.recognizes(
            bundleIdentifier: "com.logi.optionsplus"
        ))
    }

    func testRecognizesBackgroundAgent() {
        XCTAssertTrue(LogiOptionsPlusRuntime.recognizes(
            bundleIdentifier: "com.logi.cp-dev-mgr"
        ))
    }

    func testRejectsUnrelatedApplications() {
        XCTAssertFalse(LogiOptionsPlusRuntime.recognizes(
            bundleIdentifier: "com.example.unrelated"
        ))
        XCTAssertFalse(LogiOptionsPlusRuntime.recognizes(bundleIdentifier: nil))
    }
}
