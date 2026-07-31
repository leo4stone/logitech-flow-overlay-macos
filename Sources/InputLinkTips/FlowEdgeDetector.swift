import CoreGraphics
import Foundation

enum FlowEdgeEvent: Equatable {
    case leftComputer
    case returned
}

/// Infers a Logitech Flow hand-off from the cursor reaching an outside screen
/// edge and then remaining frozen there for a short period.
struct FlowEdgeDetector {
    var delay: TimeInterval
    var edgeInset: CGFloat = 16
    var movementThreshold: CGFloat = 0.75

    private(set) var isAway = false
    var isArmed: Bool { armedAt != nil }
    private var previousPoint: CGPoint?
    private var armedAt: TimeInterval?

    init(
        delay: TimeInterval,
        edgeInset: CGFloat = 16,
        movementThreshold: CGFloat = 0.75
    ) {
        self.delay = delay
        self.edgeInset = edgeInset
        self.movementThreshold = movementThreshold
    }

    mutating func observe(
        point: CGPoint,
        screens: [CGRect],
        at timestamp: TimeInterval
    ) -> FlowEdgeEvent? {
        let currentSide = Self.outsideEdge(
            point,
            screens: screens,
            inset: edgeInset
        )
        let onOutsideEdge = currentSide != nil

        guard let previousPoint else {
            self.previousPoint = point
            return nil
        }

        let deltaX = point.x - previousPoint.x
        let deltaY = point.y - previousPoint.y
        let moved = hypot(deltaX, deltaY)
            >= movementThreshold
        let previousSide = Self.outsideEdge(
            previousPoint,
            screens: screens,
            inset: edgeInset
        )
        self.previousPoint = point

        if isAway {
            if moved || !onOutsideEdge {
                isAway = false
                armedAt = nil
                return .returned
            }
            return nil
        }

        if !onOutsideEdge {
            armedAt = nil
            return nil
        }

        // Arm only on a clear outward crossing from the desktop interior. Moving
        // vertically along an edge or launching with the cursor parked there must
        // not look like a Flow hand-off.
        if armedAt == nil {
            let movedOutward = (currentSide == .left && deltaX <= -movementThreshold)
                || (currentSide == .right && deltaX >= movementThreshold)
                || (currentSide == .bottom && deltaY <= -movementThreshold)
                || (currentSide == .top && deltaY >= movementThreshold)
            if previousSide == nil && movedOutward {
                armedAt = timestamp
            }
            return nil
        }

        if timestamp - (armedAt ?? timestamp) >= delay {
            isAway = true
            return .leftComputer
        }

        return nil
    }

    mutating func reset() {
        previousPoint = nil
        armedAt = nil
        isAway = false
    }

    static func isOnOutsideVerticalEdge(
        _ point: CGPoint,
        screens: [CGRect],
        inset: CGFloat
    ) -> Bool {
        guard let edge = outsideEdge(point, screens: screens, inset: inset)
        else { return false }
        return edge == .left || edge == .right
    }

    static func isOnOutsideEdge(
        _ point: CGPoint,
        screens: [CGRect],
        inset: CGFloat
    ) -> Bool {
        outsideEdge(point, screens: screens, inset: inset) != nil
    }

    private enum EdgeSide {
        case left
        case right
        case bottom
        case top
    }

    private static func outsideEdge(
        _ point: CGPoint,
        screens: [CGRect],
        inset: CGFloat
    ) -> EdgeSide? {
        guard !screens.isEmpty else { return nil }

        for screen in screens where screen.insetBy(dx: -1, dy: -1).contains(point) {
            let atLeft = point.x <= screen.minX + inset
            let atRight = point.x >= screen.maxX - inset
            let atBottom = point.y <= screen.minY + inset
            let atTop = point.y >= screen.maxY - inset

            if atLeft {
                let probe = CGPoint(x: screen.minX - inset - 2, y: point.y)
                if !screens.contains(where: { $0.contains(probe) }) {
                    return .left
                }
            }

            if atRight {
                let probe = CGPoint(x: screen.maxX + inset + 2, y: point.y)
                if !screens.contains(where: { $0.contains(probe) }) {
                    return .right
                }
            }

            if atBottom {
                let probe = CGPoint(x: point.x, y: screen.minY - inset - 2)
                if !screens.contains(where: { $0.contains(probe) }) {
                    return .bottom
                }
            }

            if atTop {
                let probe = CGPoint(x: point.x, y: screen.maxY + inset + 2)
                if !screens.contains(where: { $0.contains(probe) }) {
                    return .top
                }
            }
        }

        return nil
    }
}
