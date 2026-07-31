import Foundation

struct ReconnectAlertSettings: Equatable {
    static let defaultEnabled = true
    static let minimumDimOpacity = 0.0
    static let maximumDimOpacity = 0.85
    static let defaultDimOpacity = 0.50
    static let minimumDuration = 0.5
    static let maximumDuration = 5.0
    static let defaultDuration = 2.0
    static let minimumRadius = 60.0
    static let maximumRadius = 320.0
    static let defaultRadius = 100.0
    static let minimumFeather = 0.0
    static let maximumFeather = 1.0
    static let defaultFeather = 0.04

    var isEnabled: Bool
    var dimOpacity: Double
    var duration: Double
    var radius: Double
    var feather: Double

    init(
        isEnabled: Bool,
        dimOpacity: Double,
        duration: Double,
        radius: Double,
        feather: Double
    ) {
        self.isEnabled = isEnabled
        self.dimOpacity = Self.normalizedDimOpacity(dimOpacity)
        self.duration = Self.normalizedDuration(duration)
        self.radius = Self.normalizedRadius(radius)
        self.feather = Self.normalizedFeather(feather)
    }

    static func normalizedDimOpacity(_ value: Double) -> Double {
        min(max(value, minimumDimOpacity), maximumDimOpacity)
    }

    static func normalizedDuration(_ value: Double) -> Double {
        min(max(value, minimumDuration), maximumDuration)
    }

    static func normalizedRadius(_ value: Double) -> Double {
        min(max(value, minimumRadius), maximumRadius)
    }

    static func normalizedFeather(_ value: Double) -> Double {
        min(max(value, minimumFeather), maximumFeather)
    }
}
