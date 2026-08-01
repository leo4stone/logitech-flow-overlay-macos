import Foundation

struct ReconnectSpotlightColor: Equatable {
    static let defaultValue = ReconnectSpotlightColor(
        red: 1,
        green: 1,
        blue: 1,
        alpha: 0.20
    )

    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = Self.normalized(red)
        self.green = Self.normalized(green)
        self.blue = Self.normalized(blue)
        self.alpha = Self.normalized(alpha)
    }

    private static func normalized(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

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
    static let defaultSpotlightColor = ReconnectSpotlightColor.defaultValue

    var isEnabled: Bool
    var dimOpacity: Double
    var duration: Double
    var radius: Double
    var feather: Double
    var spotlightColor: ReconnectSpotlightColor

    init(
        isEnabled: Bool,
        dimOpacity: Double,
        duration: Double,
        radius: Double,
        feather: Double,
        spotlightColor: ReconnectSpotlightColor
    ) {
        self.isEnabled = isEnabled
        self.dimOpacity = Self.normalizedDimOpacity(dimOpacity)
        self.duration = Self.normalizedDuration(duration)
        self.radius = Self.normalizedRadius(radius)
        self.feather = Self.normalizedFeather(feather)
        self.spotlightColor = spotlightColor
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
