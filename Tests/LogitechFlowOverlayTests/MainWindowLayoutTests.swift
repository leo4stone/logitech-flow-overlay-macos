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

    func testTriggerEdgeControlsReflectSettingsAndGlobalState() throws {
        let controller = MainWindowController()
        controller.updateActiveDeviceDetectionSettings(
            ActiveDeviceDetectionSettings(
                isEnabled: true,
                triggerEdges: [.left, .top]
            )
        )
        let buttons = allButtons(in: try XCTUnwrap(
            controller.window?.contentView
        ))

        XCTAssertEqual(
            try button(titled: L10n.leftEdge, in: buttons).state,
            .on
        )
        XCTAssertEqual(
            try button(titled: L10n.rightEdge, in: buttons).state,
            .off
        )
        XCTAssertEqual(
            try button(titled: L10n.topEdge, in: buttons).state,
            .on
        )
        XCTAssertEqual(
            try button(titled: L10n.bottomEdge, in: buttons).state,
            .off
        )

        controller.updateActiveDeviceDetectionSettings(
            ActiveDeviceDetectionSettings(
                isEnabled: false,
                triggerEdges: .all
            )
        )
        for title in [
            L10n.leftEdge,
            L10n.rightEdge,
            L10n.topEdge,
            L10n.bottomEdge
        ] {
            XCTAssertFalse(try button(titled: title, in: buttons).isEnabled)
        }
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

    private func allButtons(in view: NSView) -> [NSButton] {
        var result: [NSButton] = []
        if let button = view as? NSButton {
            result.append(button)
        }
        for subview in view.subviews {
            result.append(contentsOf: allButtons(in: subview))
        }
        return result
    }

    private func button(
        titled title: String,
        in buttons: [NSButton]
    ) throws -> NSButton {
        try XCTUnwrap(buttons.first { $0.title == title })
    }
}
