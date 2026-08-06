import CoreGraphics
import XCTest
@testable import LogitechFlowOverlay

final class FlowEdgeDetectorTests: XCTestCase {
    private let oneScreen = [CGRect(x: 0, y: 0, width: 1440, height: 900)]

    func testTriggersAfterCursorArrivesAndFreezesAtOutsideEdge() {
        var detector = FlowEdgeDetector(delay: 0.6)

        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1200, y: 400),
            screens: oneScreen,
            at: 1
        ))
        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1439, y: 400),
            screens: oneScreen,
            at: 1.1
        ))
        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1439, y: 400),
            screens: oneScreen,
            at: 1.6
        ))
        XCTAssertEqual(
            detector.observe(
                point: CGPoint(x: 1439, y: 400),
                screens: oneScreen,
                at: 1.71
            ),
            .leftComputer
        )
    }

    func testMovementAfterAwaySignalsReturn() {
        var detector = FlowEdgeDetector(delay: 0.1)
        _ = detector.observe(point: CGPoint(x: 100, y: 300), screens: oneScreen, at: 1)
        _ = detector.observe(point: CGPoint(x: 1, y: 300), screens: oneScreen, at: 1.1)
        _ = detector.observe(point: CGPoint(x: 1, y: 300), screens: oneScreen, at: 1.21)

        XCTAssertEqual(
            detector.observe(
                point: CGPoint(x: 30, y: 300),
                screens: oneScreen,
                at: 1.3
            ),
            .returned
        )
    }

    func testLongObservationGapPreservesAwayAndSignalsReturn() {
        var detector = FlowEdgeDetector(delay: 0.1)
        _ = detector.observe(
            point: CGPoint(x: 100, y: 300),
            screens: oneScreen,
            at: 1
        )
        _ = detector.observe(
            point: CGPoint(x: 1, y: 300),
            screens: oneScreen,
            at: 1.1
        )
        XCTAssertEqual(
            detector.observe(
                point: CGPoint(x: 1, y: 300),
                screens: oneScreen,
                at: 1.21
            ),
            .leftComputer
        )

        XCTAssertEqual(
            detector.observe(
                point: CGPoint(x: 30, y: 300),
                screens: oneScreen,
                at: 601.21
            ),
            .returned
        )
    }

    func testDoesNotTriggerWhenAppStartsWithCursorAtEdge() {
        var detector = FlowEdgeDetector(delay: 0.1)
        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1, y: 300),
            screens: oneScreen,
            at: 1
        ))
        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1, y: 300),
            screens: oneScreen,
            at: 2
        ))
    }

    func testVerticalMovementAlongEdgeDoesNotArm() {
        var detector = FlowEdgeDetector(delay: 0.1)
        _ = detector.observe(point: CGPoint(x: 1, y: 300), screens: oneScreen, at: 1)
        _ = detector.observe(point: CGPoint(x: 1, y: 500), screens: oneScreen, at: 1.1)

        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1, y: 500),
            screens: oneScreen,
            at: 2
        ))
    }

    func testSharedEdgeBetweenTwoDisplaysIsNotAnOutsideEdge() {
        let screens = [
            CGRect(x: 0, y: 0, width: 1440, height: 900),
            CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        ]

        XCTAssertFalse(FlowEdgeDetector.isOnOutsideVerticalEdge(
            CGPoint(x: 1439, y: 400),
            screens: screens,
            inset: 2
        ))
        XCTAssertTrue(FlowEdgeDetector.isOnOutsideVerticalEdge(
            CGPoint(x: 3359, y: 400),
            screens: screens,
            inset: 2
        ))
    }

    func testTriggersAtTopEdgeForVerticallyArrangedFlowHost() {
        var detector = FlowEdgeDetector(delay: 0.1)
        _ = detector.observe(point: CGPoint(x: 700, y: 700), screens: oneScreen, at: 1)
        _ = detector.observe(point: CGPoint(x: 700, y: 899), screens: oneScreen, at: 1.1)

        XCTAssertEqual(
            detector.observe(
                point: CGPoint(x: 700, y: 899),
                screens: oneScreen,
                at: 1.21
            ),
            .leftComputer
        )
    }

    func testStackedDisplaysDoNotTriggerAtSharedHorizontalEdge() {
        let screens = [
            CGRect(x: 0, y: 0, width: 1440, height: 900),
            CGRect(x: 0, y: 900, width: 1440, height: 900)
        ]

        XCTAssertFalse(FlowEdgeDetector.isOnOutsideEdge(
            CGPoint(x: 700, y: 899),
            screens: screens,
            inset: 16
        ))
        XCTAssertTrue(FlowEdgeDetector.isOnOutsideEdge(
            CGPoint(x: 700, y: 1799),
            screens: screens,
            inset: 16
        ))
    }

    func testOnlySelectedEdgesAreEligible() {
        let edgePoints: [(CGPoint, FlowTriggerEdges)] = [
            (CGPoint(x: 1, y: 450), .left),
            (CGPoint(x: 1439, y: 450), .right),
            (CGPoint(x: 700, y: 1), .bottom),
            (CGPoint(x: 700, y: 899), .top)
        ]

        for (point, edge) in edgePoints {
            XCTAssertTrue(FlowEdgeDetector.isOnOutsideEdge(
                point,
                screens: oneScreen,
                inset: 16,
                triggerEdges: edge
            ))
            XCTAssertFalse(FlowEdgeDetector.isOnOutsideEdge(
                point,
                screens: oneScreen,
                inset: 16,
                triggerEdges: FlowTriggerEdges.all.subtracting(edge)
            ))
        }
    }

    func testDisabledEdgeDoesNotArmDetector() {
        var detector = FlowEdgeDetector(
            delay: 0.1,
            triggerEdges: [.left]
        )
        _ = detector.observe(
            point: CGPoint(x: 1200, y: 400),
            screens: oneScreen,
            at: 1
        )
        _ = detector.observe(
            point: CGPoint(x: 1439, y: 400),
            screens: oneScreen,
            at: 1.1
        )

        XCTAssertNil(detector.observe(
            point: CGPoint(x: 1439, y: 400),
            screens: oneScreen,
            at: 2
        ))
        XCTAssertFalse(detector.isArmed)
    }

    func testCornerUsesEnabledMovementDirection() {
        var detector = FlowEdgeDetector(
            delay: 0.1,
            triggerEdges: [.top]
        )
        _ = detector.observe(
            point: CGPoint(x: 20, y: 700),
            screens: oneScreen,
            at: 1
        )
        _ = detector.observe(
            point: CGPoint(x: 1, y: 899),
            screens: oneScreen,
            at: 1.1
        )

        XCTAssertTrue(detector.isArmed)
        XCTAssertEqual(
            detector.observe(
                point: CGPoint(x: 1, y: 899),
                screens: oneScreen,
                at: 1.21
            ),
            .leftComputer
        )
    }
}
