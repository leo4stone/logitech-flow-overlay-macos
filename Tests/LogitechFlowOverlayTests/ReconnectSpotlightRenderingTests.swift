import AppKit
import XCTest
@testable import LogitechFlowOverlay

final class ReconnectSpotlightRenderingTests: XCTestCase {
    func testHardEdgeLeavesCenterTransparentAndDimsOutside() throws {
        let image = try renderSpotlight(feather: 0)

        XCTAssertEqual(
            try alpha(in: image, x: 200, y: 200),
            0,
            accuracy: 0.02
        )
        XCTAssertEqual(
            try alpha(in: image, x: 20, y: 20),
            0.80,
            accuracy: 0.04
        )
    }

    func testFeatherCreatesContinuousTransition() throws {
        let image = try renderSpotlight(feather: 0.50)
        let centerAlpha = try alpha(in: image, x: 200, y: 200)
        let transitionAlpha = try alpha(in: image, x: 290, y: 200)
        let outsideAlpha = try alpha(in: image, x: 20, y: 20)

        XCTAssertEqual(centerAlpha, 0, accuracy: 0.02)
        XCTAssertGreaterThan(transitionAlpha, centerAlpha)
        XCTAssertLessThan(transitionAlpha, outsideAlpha)
        XCTAssertEqual(outsideAlpha, 0.80, accuracy: 0.04)
    }

    private func renderSpotlight(
        feather: CGFloat
    ) throws -> NSBitmapImageRep {
        let view = ReconnectSpotlightView(
            frame: NSRect(x: 0, y: 0, width: 400, height: 400)
        )
        view.dimOpacity = 0.80
        view.spotlightRadius = 120
        view.feather = feather
        view.pointerLocation = CGPoint(x: 200, y: 200)

        guard let image = view.bitmapImageRepForCachingDisplay(
            in: view.bounds
        ) else {
            throw RenderingError.unavailable
        }
        view.cacheDisplay(in: view.bounds, to: image)
        return image
    }

    private func alpha(
        in image: NSBitmapImageRep,
        x: Int,
        y: Int
    ) throws -> CGFloat {
        guard let color = image.colorAt(x: x, y: y) else {
            throw RenderingError.unavailable
        }
        return color.alphaComponent
    }

    private enum RenderingError: Error {
        case unavailable
    }
}
