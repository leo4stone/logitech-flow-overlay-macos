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
    var triggerEdges: FlowTriggerEdges = .all

    private(set) var isAway = false
    var isArmed: Bool { armedAt != nil }
    private var previousPoint: CGPoint?
    private var armedAt: TimeInterval?

    init(
        delay: TimeInterval,
        edgeInset: CGFloat = 16,
        movementThreshold: CGFloat = 0.75,
        triggerEdges: FlowTriggerEdges = .all
    ) {
        self.delay = delay
        self.edgeInset = edgeInset
        self.movementThreshold = movementThreshold
        self.triggerEdges = triggerEdges
    }

    mutating func observe(
        point: CGPoint,
        screens: [CGRect],
        at timestamp: TimeInterval
    ) -> FlowEdgeEvent? {
        let currentEdges = Self.outsideEdges(
            point,
            screens: screens,
            inset: edgeInset,
            triggerEdges: triggerEdges
        )
        let onOutsideEdge = !currentEdges.isEmpty

        guard let previousPoint else {
            self.previousPoint = point
            return nil
        }

        let deltaX = point.x - previousPoint.x
        let deltaY = point.y - previousPoint.y
        let moved = hypot(deltaX, deltaY)
            >= movementThreshold
        let previousEdges = Self.outsideEdges(
            previousPoint,
            screens: screens,
            inset: edgeInset,
            triggerEdges: triggerEdges
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
            let movedOutward =
                (
                    currentEdges.contains(.left)
                        && deltaX <= -movementThreshold
                )
                || (
                    currentEdges.contains(.right)
                        && deltaX >= movementThreshold
                )
                || (
                    currentEdges.contains(.bottom)
                        && deltaY <= -movementThreshold
                )
                || (
                    currentEdges.contains(.top)
                        && deltaY >= movementThreshold
                )
            if previousEdges.isEmpty && movedOutward {
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
        let edges = outsideEdges(
            point,
            screens: screens,
            inset: inset,
            triggerEdges: .all
        )
        return !edges.intersection([.left, .right]).isEmpty
    }

    static func isOnOutsideEdge(
        _ point: CGPoint,
        screens: [CGRect],
        inset: CGFloat,
        triggerEdges: FlowTriggerEdges = .all
    ) -> Bool {
        !outsideEdges(
            point,
            screens: screens,
            inset: inset,
            triggerEdges: triggerEdges
        ).isEmpty
    }

    private static func outsideEdges(
        _ point: CGPoint,
        screens: [CGRect],
        inset: CGFloat,
        triggerEdges: FlowTriggerEdges
    ) -> FlowTriggerEdges {
        guard !screens.isEmpty else { return [] }

        var result: FlowTriggerEdges = []

        for screen in screens where screen.insetBy(dx: -1, dy: -1).contains(point) {
            let atLeft = point.x <= screen.minX + inset
            let atRight = point.x >= screen.maxX - inset
            let atBottom = point.y <= screen.minY + inset
            let atTop = point.y >= screen.maxY - inset

            if atLeft && triggerEdges.contains(.left) {
                let probe = CGPoint(x: screen.minX - inset - 2, y: point.y)
                if !screens.contains(where: { $0.contains(probe) }) {
                    result.insert(.left)
                }
            }

            if atRight && triggerEdges.contains(.right) {
                let probe = CGPoint(x: screen.maxX + inset + 2, y: point.y)
                if !screens.contains(where: { $0.contains(probe) }) {
                    result.insert(.right)
                }
            }

            if atBottom && triggerEdges.contains(.bottom) {
                let probe = CGPoint(x: point.x, y: screen.minY - inset - 2)
                if !screens.contains(where: { $0.contains(probe) }) {
                    result.insert(.bottom)
                }
            }

            if atTop && triggerEdges.contains(.top) {
                let probe = CGPoint(x: point.x, y: screen.maxY + inset + 2)
                if !screens.contains(where: { $0.contains(probe) }) {
                    result.insert(.top)
                }
            }
        }

        return result
    }
}
