import Foundation

struct FlowTriggerEdges: OptionSet, Equatable {
    let rawValue: Int

    static let left = FlowTriggerEdges(rawValue: 1 << 0)
    static let right = FlowTriggerEdges(rawValue: 1 << 1)
    static let bottom = FlowTriggerEdges(rawValue: 1 << 2)
    static let top = FlowTriggerEdges(rawValue: 1 << 3)
    static let all: FlowTriggerEdges = [.left, .right, .bottom, .top]
}

struct ActiveDeviceDetectionSettings: Equatable {
    static let defaultEnabled = true
    static let defaultTriggerEdges = FlowTriggerEdges.all

    let isEnabled: Bool
    let triggerEdges: FlowTriggerEdges

    init(
        isEnabled: Bool,
        triggerEdges: FlowTriggerEdges
    ) {
        self.isEnabled = isEnabled
        self.triggerEdges = FlowTriggerEdges(
            rawValue: triggerEdges.rawValue
                & FlowTriggerEdges.all.rawValue
        )
    }
}
