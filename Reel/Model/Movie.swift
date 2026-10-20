import SwiftUI

/// A film in the bundled catalog. Every film carries its own art direction
/// (palette, motif, typeface) so the app can print a unique poster for it.
nonisolated struct Movie: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let year: Int
    let runtime: Int
    let director: String
    let cast: [String]
    let genres: [String]
    let moods: [Mood]
    let logline: String
    let palette: [String]
    let motif: Motif
    let typeface: Typeface

    var decade: Int { year / 10 * 10 }

    var runtimeLabel: String {
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours == 0 { return "\(minutes)m" }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    /// Poster background.
    var base: Color { Color(hex: palette[0]) }
    /// The loud colour: motifs, glows, the ambient light behind the UI.
    var accent: Color { Color(hex: palette[1]) }
    /// Typography colour, chosen to read on `base`.
    var ink: Color { Color(hex: palette[2]) }

    /// Accent tuned to glow on the app's near-black chrome. Dark accents
    /// (e.g. a black monolith on a white poster) fall back to the base colour.
    var glow: Color {
        let accentLuma = Color.luminance(hex: palette[1])
        let baseLuma = Color.luminance(hex: palette[0])
        if accentLuma > 0.18 { return accent }
        return baseLuma > accentLuma ? base : accent.mix(with: .white, by: 0.4)
    }

    /// Stable 64-bit seed for generative art.
    var seed: UInt64 { StableHash.of(id) }
}

nonisolated enum Mood: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case mindBending, dread, heartache, adrenaline, dreamy, cozy, lonely, epic, laugh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mindBending: "Mind-bending"
        case .dread: "Dread"
        case .heartache: "Heartache"
        case .adrenaline: "Adrenaline"
        case .dreamy: "Dreamy"
        case .cozy: "Cozy"
        case .lonely: "Lonely"
        case .epic: "Epic"
        case .laugh: "Laugh"
        }
    }

    var symbol: String {
        switch self {
        case .mindBending: "hurricane"
        case .dread: "eye.fill"
        case .heartache: "heart.fill"
        case .adrenaline: "bolt.fill"
        case .dreamy: "moon.stars.fill"
        case .cozy: "cup.and.saucer.fill"
        case .lonely: "cloud.rain.fill"
        case .epic: "mountain.2.fill"
        case .laugh: "face.smiling.inverse"
        }
    }

    var tint: Color {
        switch self {
        case .mindBending: Color(hex: "#9B8CFF")
        case .dread: Color(hex: "#FF5D5D")
        case .heartache: Color(hex: "#FF7FA8")
        case .adrenaline: Color(hex: "#FFC93C")
        case .dreamy: Color(hex: "#7FD1FF")
        case .cozy: Color(hex: "#FFAE73")
        case .lonely: Color(hex: "#8FA6C4")
        case .epic: Color(hex: "#7EE0B5")
        case .laugh: Color(hex: "#FFE066")
        }
    }
}

/// The graphic idea at the centre of a generated poster.
nonisolated enum Motif: String, Codable, CaseIterable, Sendable {
    case sun, orbit, monolith, horizon, grid, rain, rings, split, stairs
    case bloom, wave, eye, arch, shards, stripes, spiral, halftone, burst
}

/// Poster typefaces, all of which ship with iOS.
nonisolated enum Typeface: String, Codable, Sendable {
    case futura, didot, avenir, bodoni, optima, gill, typewriter, copperplate

    private var postScriptName: String {
        switch self {
        case .futura: "Futura-CondensedExtraBold"
        case .didot: "Didot-Bold"
        case .avenir: "AvenirNextCondensed-Heavy"
        case .bodoni: "BodoniSvtyTwoITCTT-Bold"
        case .optima: "Optima-ExtraBlack"
        case .gill: "GillSans-Bold"
        case .typewriter: "AmericanTypewriter-CondensedBold"
        case .copperplate: "Copperplate-Bold"
        }
    }

    /// Condensed faces are set larger and in caps; the classic serifs stay mixed-case.
    var isUppercase: Bool {
        switch self {
        case .didot, .bodoni: false
        default: true
        }
    }

    private var scale: CGFloat {
        switch self {
        case .futura, .avenir, .typewriter: 0.165
        case .gill, .optima: 0.14
        case .copperplate: 0.12
        case .didot, .bodoni: 0.145
        }
    }

    func titleFont(posterWidth: CGFloat) -> Font {
        .custom(postScriptName, fixedSize: posterWidth * scale)
    }
}
