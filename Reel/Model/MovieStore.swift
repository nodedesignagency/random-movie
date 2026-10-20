import SwiftUI

/// The catalog, the current filtered deck, and the user's saved stubs.
@Observable
final class MovieStore {
    let catalog: [Movie]

    /// The catalog shuffled once per launch, so the reel feels different every time you open it.
    private let shuffled: [Movie]

    var filters = Filters() {
        didSet {
            guard filters != oldValue else { return }
            rebuildDeck()
        }
    }

    private(set) var deck: [Movie] = []
    /// Bumped whenever `deck` is rebuilt, so views can reset scroll state.
    private(set) var deckVersion = 0

    private(set) var savedIDs: [String]
    private(set) var watchedIDs: Set<String>

    private let defaults: UserDefaults
    private static let savedKey = "reel.saved"
    private static let watchedKey = "reel.watched"

    init(catalog: [Movie]? = nil, defaults: UserDefaults = .standard) {
        let movies = catalog ?? MovieStore.loadBundledCatalog()
        self.catalog = movies
        self.shuffled = movies.shuffled()
        self.defaults = defaults
        self.savedIDs = defaults.stringArray(forKey: Self.savedKey) ?? []
        self.watchedIDs = Set(defaults.stringArray(forKey: Self.watchedKey) ?? [])
        rebuildDeck()
    }

    // MARK: Deck

    func movie(at index: Int) -> Movie? {
        deck.indices.contains(index) ? deck[index] : nil
    }

    /// A random deck index that isn't `current`, when there's any choice at all.
    func randomIndex(excluding current: Int) -> Int? {
        guard !deck.isEmpty else { return nil }
        guard deck.count > 1 else { return 0 }
        var pick = Int.random(in: 0..<(deck.count - 1))
        if pick >= current { pick += 1 }
        return pick
    }

    func count(matching filters: Filters) -> Int {
        catalog.reduce(0) { $0 + (filters.matches($1) ? 1 : 0) }
    }

    private func rebuildDeck() {
        deck = shuffled.filter(filters.matches)
        deckVersion += 1
    }

    // MARK: Orbit

    func related(to movie: Movie, limit: Int = 6) -> [Relation] {
        RelationGraph.related(to: movie, in: catalog, limit: limit)
    }

    // MARK: Stubs

    var savedMovies: [Movie] {
        let byID = Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, $0) })
        return savedIDs.compactMap { byID[$0] }
    }

    func isSaved(_ movie: Movie) -> Bool { savedIDs.contains(movie.id) }
    func isWatched(_ movie: Movie) -> Bool { watchedIDs.contains(movie.id) }

    func toggleSaved(_ movie: Movie) {
        if let index = savedIDs.firstIndex(of: movie.id) {
            savedIDs.remove(at: index)
            watchedIDs.remove(movie.id)
        } else {
            savedIDs.insert(movie.id, at: 0)
        }
        persist()
    }

    func toggleWatched(_ movie: Movie) {
        if watchedIDs.contains(movie.id) {
            watchedIDs.remove(movie.id)
        } else {
            watchedIDs.insert(movie.id)
            if !savedIDs.contains(movie.id) { savedIDs.insert(movie.id, at: 0) }
        }
        persist()
    }

    /// Ticket number printed on a stub: its position in the order films were saved.
    func stubNumber(for movie: Movie) -> Int {
        guard let index = savedIDs.firstIndex(of: movie.id) else { return 0 }
        return savedIDs.count - index
    }

    private func persist() {
        defaults.set(savedIDs, forKey: Self.savedKey)
        defaults.set(Array(watchedIDs), forKey: Self.watchedKey)
    }

    // MARK: Loading

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
