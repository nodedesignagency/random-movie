import SwiftUI

struct RootView: View {
    @State private var store = MovieStore()
    @State private var scroller = ReelScroller()
    @State private var orbit = OrbitModel()
    @State private var tab: AppTab = .reel
    @State private var showFilters = false
    @State private var detail: Movie?
    @State private var spins = 0
    @Namespace private var zoom

    /// The light behind everything follows whatever film has your attention.
    private var focusTint: Color {
        switch tab {
        case .reel: store.movie(at: scroller.index)?.glow ?? Theme.ember
        case .orbit: orbit.center?.glow ?? Theme.ember
        case .stubs: store.savedMovies.first?.glow ?? Theme.ember
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground(tint: focusTint)

            Group {
                switch tab {
                case .reel:
                    ReelScreen(scroller: scroller, zoom: zoom, showFilters: $showFilters, onOpen: open)
                case .orbit:
                    OrbitScreen(model: orbit, fallback: store.movie(at: scroller.index), zoom: zoom, onOpen: open)
                case .stubs:
                    StubsScreen(zoom: zoom, onOpen: open, onBrowse: { withAnimation(.snappy) { tab = .reel } })
                }
            }
            .transition(.blurReplace)

            GrainOverlay()
        }
        .overlay(alignment: .bottom) {
            if !showFilters {
                GlassTabBar(selection: $tab, spins: spins, onSpin: spin)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environment(store)
        .fullScreenCover(item: $detail) { movie in
            MovieDetailView(movie: movie, onOrbit: startOrbit)
                .environment(store)
                .navigationTransition(.zoom(sourceID: movie.id, in: zoom))
        }
        .onReceive(NotificationCenter.default.publisher(for: .reelDeviceDidShake)) { _ in
            spin()
        }
        .task { applyLaunchOptions() }
    }

    // MARK: Actions

    private func open(_ movie: Movie) {
        detail = movie
    }

    private func spin() {
        guard !store.deck.isEmpty, detail == nil else { return }
        if scroller.count != store.deck.count { scroller.reset(count: store.deck.count) }
        if showFilters { withAnimation(.bouncy(duration: 0.45)) { showFilters = false } }
        if tab != .reel { withAnimation(.snappy) { tab = .reel } }
        guard let target = store.randomIndex(excluding: scroller.index) else { return }
        spins += 1
        scroller.spin(toIndex: target)
    }

    private func startOrbit(from movie: Movie) {
        detail = nil
        // Let the detail page zoom away before the constellation forms.
        Task {
            try? await Task.sleep(for: .milliseconds(380))
            orbit.start(at: movie)
            withAnimation(.smooth(duration: 0.45)) { tab = .orbit }
        }
    }

    /// Debug-only launch arguments used to stage screenshots, e.g.
    /// `-ReelStartTab orbit -ReelOrbitPath inception,the-dark-knight`.
    private func applyLaunchOptions() {
        #if DEBUG
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "ReelSeedStubs"), store.savedIDs.isEmpty {
            let picks = ["her", "blade-runner-2049", "spirited-away", "parasite", "in-the-mood-for-love", "the-matrix"]
            for id in picks.reversed() {
                if let movie = store.catalog.first(where: { $0.id == id }) { store.toggleSaved(movie) }
            }
            if let seen = store.catalog.first(where: { $0.id == "spirited-away" }) { store.toggleWatched(seen) }
        }
        if let path = defaults.string(forKey: "ReelOrbitPath") {
            let movies = path.split(separator: ",").compactMap { id in store.catalog.first { $0.id == String(id) } }
            if let first = movies.first {
                orbit.start(at: first)
                movies.dropFirst().forEach(orbit.dive(into:))
            }
        }
        if let raw = defaults.string(forKey: "ReelStartTab"), let start = AppTab(rawValue: raw) {
            tab = start
        }
        if defaults.bool(forKey: "ReelShowFilters") {
            showFilters = true
        }
        if let id = defaults.string(forKey: "ReelOpenDetail"), let movie = store.catalog.first(where: { $0.id == id }) {
            detail = movie
        }
        if defaults.bool(forKey: "ReelAutoSpin") {
            Task {
                try? await Task.sleep(for: .seconds(2))
                spin()
            }
        }
        #endif
    }
}
