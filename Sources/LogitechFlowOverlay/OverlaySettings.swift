import Foundation

struct OverlaySettings: Equatable {
    static let minimumTransparency = 0.10
    static let maximumTransparency = 0.85
    static let defaultTransparency = 0.20
    static let minimumGlassIntensity = 0.0
    static let maximumGlassIntensity = 1.0
    static let defaultGlassIntensity = 0.80
    static let minimumGlassMaskAlpha = 0.60
    static let glassResponseExponent = 2.321928094887362
    static let maximumMessageLength = 120

    var transparency: Double
    var glassIntensity: Double
    var message: String

    init(
        transparency: Double,
        glassIntensity: Double = Self.defaultGlassIntensity,
        message: String,
        defaultMessage: String = L10n.overlayTitle
    ) {
        self.transparency = Self.normalizedTransparency(transparency)
        self.glassIntensity = Self.normalizedGlassIntensity(glassIntensity)
        self.message = Self.normalizedMessage(
            message,
            defaultMessage: defaultMessage
        )
    }

    var tintAlpha: Double {
        transparency
    }

    var glassMaskAlpha: Double {
        let response = 1 - pow(
            1 - glassIntensity,
            Self.glassResponseExponent
        )
        return Self.minimumGlassMaskAlpha
            + (
                (1 - Self.minimumGlassMaskAlpha)
                * response
            )
    }

    static func normalizedTransparency(_ value: Double) -> Double {
        min(max(value, minimumTransparency), maximumTransparency)
    }

    static func normalizedGlassIntensity(_ value: Double) -> Double {
        min(max(value, minimumGlassIntensity), maximumGlassIntensity)
    }

    static func normalizedMessage(
        _ value: String,
        defaultMessage: String = L10n.overlayTitle
    ) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? defaultMessage : trimmed
        return String(fallback.prefix(maximumMessageLength))
    }
}
