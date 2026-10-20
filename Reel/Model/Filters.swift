import Foundation

nonisolated struct Filters: Equatable, Sendable {
    static let eraBounds = 1950...2026

    var mood: Mood?
    var era: ClosedRange<Int> = Filters.eraBounds
    var length: Length = .any

    var isDefault: Bool { self == Filters() }

    func matches(_ movie: Movie) -> Bool {
        if let mood, !movie.moods.contains(mood) { return false }
        guard era.contains(movie.year) else { return false }
        return length.matches(runtime: movie.runtime)
    }

    enum Length: String, CaseIterable, Identifiable, Sendable {
        case any, short, long

        var id: String { rawValue }

        var title: String {
            switch self {
            case .any: "Any length"
            case .short: "Under 2h"
            case .long: "Epic 2½h+"
            }
        }

        func matches(runtime: Int) -> Bool {
            switch self {
            case .any: true
            case .short: runtime < 120
            case .long: runtime >= 150
            }
        }
    }
}
