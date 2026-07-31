import AppKit

enum LogiOptionsPlusRuntime {
    static let supportedBundleIdentifiers: Set<String> = [
        "com.logi.optionsplus",
        "com.logi.cp-dev-mgr"
    ]

    static var isRunning: Bool {
        supportedBundleIdentifiers.contains { bundleIdentifier in
            !NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleIdentifier
            ).isEmpty
        }
    }

    static func recognizes(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return supportedBundleIdentifiers.contains(bundleIdentifier)
    }
}
