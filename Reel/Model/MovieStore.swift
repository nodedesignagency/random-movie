import Foundation
import Observation

/// The rack's running order, tonight's pick, the mood filter and the shelf of saved films.
@Observable
final class MovieStore {
    /// Films in rack order. Shuffled with the date as the seed, so the rack is new every day
    /// but stays put for the evening.
    let films: [Movie]

    /// Tonight's pick. Held for the whole day; "Pick for me" replaces it.
    private(set) var pickID: String

    var mood: Mood?

    private(set) var savedIDs: [String]

    private let defaults: UserDefaults
    private let day: String
    private static let savedKey = "reel.saved"
    private static let pickKey = "reel.pick"

    init(catalog: [Movie]? = nil, defaults: UserDefaults = .standard, today: Date = .now) {
        let movies = catalog ?? MovieStore.loadBundledCatalog()
        let day = MovieStore.dayKey(today)
        var random = SplitMix64(seed: StableHash.of(day))
        let films = movies.shuffled(using: &random)

        self.films = films
        self.defaults = defaults
        self.day = day
        self.savedIDs = defaults.stringArray(forKey: Self.savedKey) ?? []

        let stored = defaults.dictionary(forKey: Self.pickKey)?[day] as? String
        if let stored, films.contains(where: { $0.id == stored }) {
            pickID = stored
        } else if films.isEmpty {
            pickID = ""
        } else {
            pickID = films[Int(StableHash.of(day + "·pick") % UInt64(films.count))].id
        }
    }

    // MARK: Rack

    var pickIndex: Int { index(of: pickID) ?? 0 }

    func index(of id: String) -> Int? { films.firstIndex { $0.id == id } }

    func film(at index: Int) -> Movie? { films.indices.contains(index) ? films[index] : nil }

    func setPick(_ movie: Movie) {
        pickID = movie.id
        defaults.set([day: movie.id], forKey: Self.pickKey)
    }

    func matchesMood(_ movie: Movie) -> Bool {
        guard let mood else { return true }
        return movie.moods.contains(mood)
    }

    func count(for mood: Mood?) -> Int {
        guard let mood else { return films.count }
        return films.reduce(0) { $0 + ($1.moods.contains(mood) ? 1 : 0) }
    }

    /// A random film in the current mood, far enough along the rack that the trip is worth watching.
    func randomIndex(awayFrom here: Int) -> Int? {
        var pool = films.indices.filter { $0 != here && matchesMood(films[$0]) }
        let far = pool.filter { abs($0 - here) >= 6 }
        if !far.isEmpty { pool = far }
        return pool.randomElement()
    }

    func related(to movie: Movie) -> Movie? {
        RelationGraph.related(to: movie, in: films, limit: 1).first?.movie
    }

    // MARK: Shelf

    var savedMovies: [Movie] {
        let byID = Dictionary(uniqueKeysWithValues: films.map { ($0.id, $0) })
        return savedIDs.compactMap { byID[$0] }
    }

    func isSaved(_ movie: Movie) -> Bool { savedIDs.contains(movie.id) }

    func toggleSaved(_ movie: Movie) {
        if let index = savedIDs.firstIndex(of: movie.id) {
            savedIDs.remove(at: index)
        } else {
            savedIDs.insert(movie.id, at: 0)
        }
        defaults.set(savedIDs, forKey: Self.savedKey)
    }

    func removeSaved(at offsets: IndexSet) {
        savedIDs.remove(atOffsets: offsets)
        defaults.set(savedIDs, forKey: Self.savedKey)
    }

    // MARK: Loading

    private static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    private static func loadBundledCatalog() -> [Movie] {
        guard let url = Bundle.main.url(forResource: "movies", withExtension: "json") else {
            assertionFailure("movies.json is missing from the app bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Movie].self, from: Data(contentsOf: url))
        } catch {
            assertionFailure("movies.json failed to decode: \(error)")
            return []
        }
    }
}
