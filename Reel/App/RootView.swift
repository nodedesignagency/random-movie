import SwiftUI

struct RootView: View {
    @State private var store = MovieStore()
    @State private var motion = RackMotion()
    @State private var shelf = CaseShelf()
    @State private var sheet: Sheet?
    @State private var detail: Movie?
    /// Bottom of the title card on screen; the rack fades out just below it so the two never collide.
    @State private var titleBottom: CGFloat = 200
    @Namespace private var zoom

    private let options = LaunchOptions.current

    enum Sheet: String, Identifiable {
        case mood, shelf
        var id: String { rawValue }
    }

    /// While "Pick for me" spins, the title holds the film it started from.
    private var shown: Movie? { store.film(at: motion.pickingFrom ?? motion.focus) }

    var body: some View {
        ZStack {
            PosterBackdrop(movie: shown,
                           poster: shown.flatMap { shelf.posters[$0.id] },
                           swatches: shown.flatMap { shelf.swatches[$0.id] })

            GeometryReader { proxy in
                RackView(store: store, motion: motion, shelf: shelf, geometry: RackGeometry(size: proxy.size), zoom: zoom) {
                    detail = $0
                }
                .mask {
                    let height = max(proxy.size.height, 1)
                    LinearGradient(stops: [.init(color: .clear, location: (titleBottom - 6) / height),
                                           .init(color: .black, location: (titleBottom + 90) / height)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .ignoresSafeArea()

            chrome
        }
        .sheet(item: $sheet) { kind in
            switch kind {
            case .mood:
                MoodSheet(current: store.mood, count: store.count(for:), onChoose: chooseMood)
            case .shelf:
                ShelfSheet(store: store, posters: shelf.posters) { movie in
                    sheet = nil
                    travel(to: movie)
                }
            }
        }
        .fullScreenCover(item: $detail) { movie in
            MovieDetailView(movie: movie,
                            poster: shelf.posters[movie.id],
                            swatches: shelf.swatches[movie.id],
                            isPick: movie.id == store.pickID,
                            isSaved: store.isSaved(movie),
                            onToggleSave: { store.toggleSaved(movie) },
                            onMoreLikeThis: { moreLike(movie) })
                .navigationTransition(.zoom(sourceID: movie.id, in: zoom))
        }
        .sensoryFeedback(.selection, trigger: motion.focus)
        .sensoryFeedback(.impact(weight: .medium), trigger: motion.landing)
        .onChange(of: motion.landing) { _, landing in
            guard let landing, landing.isPick, let movie = store.film(at: landing.index) else { return }
            store.setPick(movie)
        }
        .onChange(of: shelf.isReady) { _, ready in
            if ready { begin() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .reelDeviceDidShake)) { _ in pickForMe() }
        .task {
            prepare()
            await shelf.prepare(store.films, around: store.pickIndex)
        }
        .preferredColorScheme(.dark)
    }

    private var chrome: some View {
        VStack(spacing: 0) {
            TitleCard(movie: shown, isPick: shown?.id == store.pickID && !motion.isEntering, isPicking: motion.isPicking)
                .padding(.horizontal, 66)
                .padding(.top, 4)
                .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { bottom in
                    withAnimation(.smooth(duration: 0.35)) { titleBottom = bottom }
                }

            Spacer(minLength: 0)

            RulerView(count: store.films.count, motion: motion)
                .padding(.horizontal, 12)

            ControlBar(isSaved: shown.map(store.isSaved) ?? false,
                       hasMood: store.mood != nil,
                       onSave: { if let shown { store.toggleSaved(shown) } },
                       onPick: pickForMe,
                       onMood: { sheet = .mood })
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 4)
        }
        .overlay(alignment: .topTrailing) {
            GlassCircleButton(systemImage: "film.stack", size: 44, showsDot: !store.savedIDs.isEmpty, label: "Your shelf") {
                sheet = .shelf
            }
            .padding(.trailing, 16)
            .padding(.top, 2)
        }
        .opacity(shelf.isReady ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: shelf.isReady)
    }

    // MARK: Actions

    private func pickForMe() {
        guard detail == nil, let index = store.randomIndex(awayFrom: motion.focus) else { return }
        sheet = nil
        motion.pick(index)
    }

    private func chooseMood(_ mood: Mood?) {
        store.mood = mood
        sheet = nil
        guard mood != nil else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(380))
            pickForMe()
        }
    }

    private func travel(to movie: Movie) {
        guard let index = store.index(of: movie.id) else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(320))
            motion.go(to: index)
        }
    }

    private func moreLike(_ movie: Movie) {
        detail = nil
        guard let next = store.related(to: movie) else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            if let index = store.index(of: next.id) { motion.go(to: index) }
        }
    }

    // MARK: Start-up

    private func prepare() {
        if let id = options.pick, let movie = store.films.first(where: { $0.id == id }) { store.setPick(movie) }
        if options.seedShelf, store.savedIDs.isEmpty {
            for movie in store.films.prefix(4) { store.toggleSaved(movie) }
        }
        if let raw = options.mood { store.mood = Mood(rawValue: raw) }
        motion.configure(count: store.films.count, start: store.pickIndex)
    }

    private func begin() {
        if let time = options.poseIntro {
            motion.pose(introAt: time)
            return
        }
        if options.skipIntro { motion.skipIntro() } else { motion.playIntro() }
        Task {
            try? await Task.sleep(for: .seconds(options.skipIntro ? 0.3 : RackMotion.introDuration + 0.4))
            if let id = options.goTo, let index = store.index(of: id) { motion.go(to: index) }
            if options.autoPick { pickForMe() }
            if let raw = options.sheet { sheet = Sheet(rawValue: raw) }
            if let id = options.openDetail, let movie = store.films.first(where: { $0.id == id }) { detail = movie }
        }
    }
}

/// Launch arguments for taking screenshots and recordings, e.g. `-ReelGoTo dune -ReelSkipIntro YES`.
struct LaunchOptions {
    var pick: String?
    var goTo: String?
    var openDetail: String?
    var sheet: String?
    var mood: String?
    var autoPick = false
    var skipIntro = false
    var seedShelf = false
    var poseIntro: Double?

    static var current: LaunchOptions {
        let defaults = UserDefaults.standard
        var options = LaunchOptions()
        options.pick = defaults.string(forKey: "ReelPick")
        options.goTo = defaults.string(forKey: "ReelGoTo")
        options.openDetail = defaults.string(forKey: "ReelOpenDetail")
        options.sheet = defaults.string(forKey: "ReelSheet")
        options.mood = defaults.string(forKey: "ReelMood")
        options.autoPick = defaults.bool(forKey: "ReelAutoPick")
        options.skipIntro = defaults.bool(forKey: "ReelSkipIntro")
        options.seedShelf = defaults.bool(forKey: "ReelSeedShelf")
        options.poseIntro = defaults.object(forKey: "ReelPoseIntro") != nil ? defaults.double(forKey: "ReelPoseIntro") : nil
        return options
    }
}
