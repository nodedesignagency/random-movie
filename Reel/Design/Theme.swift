import SwiftUI

nonisolated enum Theme {
    /// The app's black. Slightly blue so glass and glows sit on it softly.
    static let night = Color(red: 0.027, green: 0.027, blue: 0.035)
    /// Signature warm accent (dice, selection, ruler handles).
    static let ember = Color(hex: "#FF6B4D")

    static let primaryText = Color.white.opacity(0.96)
    static let secondaryText = Color.white.opacity(0.6)
    static let tertiaryText = Color.white.opacity(0.34)
    static let hairline = Color.white.opacity(0.12)
}

extension Font {
    /// Editorial italic serif for titles.
    nonisolated static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif).italic()
    }

    /// Monospaced metadata: years, runtimes, counters.
    nonisolated static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Small coloured capsule for a mood.
struct MoodTag: View {
    let mood: Mood
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 4 : 5) {
            Image(systemName: mood.symbol)
                .font(.system(size: compact ? 9 : 11, weight: .bold))
            Text(mood.title)
                .font(.system(size: compact ? 11 : 13, weight: .semibold))
        }
        .foregroundStyle(mood.tint)
        .padding(.horizontal, compact ? 8 : 11)
        .padding(.vertical, compact ? 4 : 6)
        .background(mood.tint.opacity(0.14), in: .capsule)
    }
}
