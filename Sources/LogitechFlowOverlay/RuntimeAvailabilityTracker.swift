import Foundation

struct RuntimeAvailabilityTracker {
    let unavailabilityGracePeriod: TimeInterval

    private(set) var isAvailable: Bool?
    private var unavailableSince: TimeInterval?

    var isUnavailabilityPending: Bool {
        unavailableSince != nil
    }

    init(unavailabilityGracePeriod: TimeInterval) {
        self.unavailabilityGracePeriod = max(0, unavailabilityGracePeriod)
    }

    /// Returns a stable availability change. Availability is restored
    /// immediately, while an unavailable sample must remain continuous for the
    /// full grace period before it becomes authoritative.
    mutating func observe(
        rawIsAvailable: Bool,
        at timestamp: TimeInterval
    ) -> Bool? {
        if rawIsAvailable {
            unavailableSince = nil
            guard isAvailable != true else { return nil }
            isAvailable = true
            return true
        }

        guard let isAvailable else {
            self.isAvailable = false
            return false
        }
        guard isAvailable else { return nil }

        guard let unavailableSince else {
            self.unavailableSince = timestamp
            return nil
        }
        guard timestamp - unavailableSince >= unavailabilityGracePeriod else {
            return nil
        }

        self.unavailableSince = nil
        self.isAvailable = false
        return false
    }
}
