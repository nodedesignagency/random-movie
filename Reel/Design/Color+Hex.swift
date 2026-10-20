import SwiftUI

extension Color {
    /// `#RRGGBB` → sRGB colour. Malformed input renders as black rather than trapping.
    nonisolated init(hex: String) {
        let (r, g, b) = Color.components(hex: hex)
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// Relative luminance (0…1) of a `#RRGGBB` string.
    nonisolated static func luminance(hex: String) -> Double {
        let (r, g, b) = components(hex: hex)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    nonisolated private static func components(hex: String) -> (Double, Double, Double) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        let value = UInt64(text, radix: 16) ?? 0
        return (
            Double((value >> 16) & 0xFF) / 255,
            Double((value >> 8) & 0xFF) / 255,
            Double(value & 0xFF) / 255
        )
    }
}
