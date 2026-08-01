import AppKit
import XCTest
@testable import LogitechFlowOverlay

final class MainWindowLayoutTests: XCTestCase {
    func testMainWindowIsResizableAndUsesVerticalScrolling() throws {
        let controller = MainWindowController()
        let window = try XCTUnwrap(controller.window)

        XCTAssertTrue(window.styleMask.contains(.resizable))
        XCTAssertLessThanOrEqual(window.minSize.height, 500)

        let scrollView = try XCTUnwrap(
            firstScrollView(in: window.contentView)
        )
        XCTAssertTrue(scrollView.hasVerticalScroller)
        XCTAssertFalse(scrollView.hasHorizontalScroller)
        XCTAssertTrue(try XCTUnwrap(scrollView.documentView).isFlipped)
    }

    private func firstScrollView(in view: NSView?) -> NSScrollView? {
        guard let view else { return nil }
        if let scrollView = view as? NSScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let result = firstScrollView(in: subview) {
                return result
            }
        }
        return nil
    }
}
