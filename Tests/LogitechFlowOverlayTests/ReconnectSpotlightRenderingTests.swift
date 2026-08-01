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

    func testSpotlightColorCreatesVisibleColorAtCenter() throws {
        let image = try renderSpotlight(
            feather: 0.25,
            spotlightColor: NSColor(
                srgbRed: 0.25,
                green: 0.50,
                blue: 1,
                alpha: 0.40
            )
        )
        guard let centerColor = image.colorAt(x: 200, y: 200) else {
            throw RenderingError.unavailable
        }

        XCTAssertEqual(
            centerColor.alphaComponent,
            0.40,
            accuracy: 0.04
        )
        let rgbColor = try XCTUnwrap(
            centerColor.usingColorSpace(.deviceRGB)
        )
        XCTAssertEqual(rgbColor.redComponent, 0.25, accuracy: 0.04)
        XCTAssertEqual(rgbColor.greenComponent, 0.50, accuracy: 0.04)
        XCTAssertGreaterThan(rgbColor.blueComponent, 0.95)
    }

    private func renderSpotlight(
        feather: CGFloat,
        spotlightColor: NSColor = .clear
    ) throws -> NSBitmapImageRep {
        let view = ReconnectSpotlightView(
            frame: NSRect(x: 0, y: 0, width: 400, height: 400)
        )
        view.dimOpacity = 0.80
        view.spotlightRadius = 120
        view.feather = feather
        view.spotlightColor = spotlightColor
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
