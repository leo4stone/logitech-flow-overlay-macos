import Foundation

struct OverlaySettings: Equatable {
    static let minimumTransparency = 0.10
    static let maximumTransparency = 0.85
    static let defaultTransparency = 0.42
    static let maximumMessageLength = 120

    var transparency: Double
    var message: String

    init(
        transparency: Double,
        message: String,
        defaultMessage: String = L10n.overlayTitle
    ) {
        self.transparency = Self.normalizedTransparency(transparency)
        self.message = Self.normalizedMessage(
            message,
            defaultMessage: defaultMessage
        )
    }

    var tintAlpha: Double {
        transparency
    }

    var blurAlpha: Double {
        transparency
    }

    static func normalizedTransparency(_ value: Double) -> Double {
        min(max(value, minimumTransparency), maximumTransparency)
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
