import SwiftUI

/// A film in the bundled catalog. `poster` and `backdrop` are TMDB image paths; the poster also
/// ships in the app bundle so the rack can be built offline.
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
    let poster: String
    let backdrop: String

    var decade: Int { year / 10 * 10 }

    var runtimeLabel: String {
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours == 0 { return "\(minutes)m" }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }

    var primaryGenre: String { genres.first ?? "Film" }

    /// Stand-in colour for the backdrop until the poster has been sampled.
    var base: Color { Color(hex: palette.first ?? "#141414") }

    var backdropURL: URL? { URL(string: "https://image.tmdb.org/t/p/w1280/\(backdrop)") }

    /// Name of the poster file bundled in Resources/Posters.
    var bundledPosterName: String { "poster-\(id)" }
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
}
