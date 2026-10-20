import Foundation

/// Why two films sit next to each other in the Orbit.
nonisolated enum Connection: Hashable, Sendable {
    case director(String)
    case actor(String)
    case mood(Mood)
    case genre(String)
    case era(Int)

    var label: String {
        switch self {
        case .director(let name): "Dir. \(name)"
        case .actor(let name): name
        case .mood(let mood): mood.title
        case .genre(let genre): genre
        case .era(let decade): decade < 2000 ? "The ’\(decade % 100)s" : "The \(decade)s"
        }
    }

    var symbol: String {
        switch self {
        case .director: "megaphone.fill"
        case .actor: "person.fill"
        case .mood(let mood): mood.symbol
        case .genre: "film.fill"
        case .era: "clock.fill"
        }
    }
}

nonisolated struct Relation: Identifiable, Hashable, Sendable {
    let movie: Movie
    let link: Connection
    let score: Double

    var id: String { movie.id }
}

nonisolated enum RelationGraph {
    /// Ranks every other film by how strongly it connects to `movie`.
    /// Strong, specific links (same director, shared cast) dominate; moods and
    /// genres fill the remaining slots. A stable per-pair jitter breaks ties so
    /// the constellation feels curated rather than alphabetical.
    static func related(to movie: Movie, in catalog: [Movie], limit: Int) -> [Relation] {
        var relations: [Relation] = []
        relations.reserveCapacity(catalog.count)

        for other in catalog where other.id != movie.id {
            var links: [(link: Connection, weight: Double)] = []
            if other.director == movie.director { links.append((.director(movie.director), 6)) }
            for actor in movie.cast where other.cast.contains(actor) { links.append((.actor(actor), 4.5)) }
            for mood in movie.moods where other.moods.contains(mood) { links.append((.mood(mood), 1.5)) }
            for genre in movie.genres where other.genres.contains(genre) { links.append((.genre(genre), 1.1)) }
            if other.decade == movie.decade { links.append((.era(movie.decade), 0.6)) }

            // `max(by:)` keeps the first of equal maxima, and links are appended most specific first.
            guard let strongest = links.max(by: { $0.weight < $1.weight }) else { continue }
            let score = links.reduce(0) { $0 + $1.weight }
            let jitter = Double(StableHash.of(movie.id + "→" + other.id) % 1000) / 1000 * 0.9
            relations.append(Relation(movie: other, link: strongest.link, score: score + jitter))
        }

        relations.sort { $0.score > $1.score }
        return Array(relations.prefix(limit))
    }
}
