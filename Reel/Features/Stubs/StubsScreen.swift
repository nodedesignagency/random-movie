import SwiftUI

/// Your saved films as a pocketful of tickets.
struct StubsScreen: View {
    @Environment(MovieStore.self) private var store
    let zoom: Namespace.ID
    var onOpen: (Movie) -> Void
    var onBrowse: () -> Void

    @State private var shelf: Shelf = .toWatch
    @Namespace private var pill

    private enum Shelf: String, CaseIterable, Identifiable {
        case toWatch, watched
        var id: String { rawValue }
        var title: String { self == .toWatch ? "To watch" : "Watched" }
    }

    var body: some View {
        let saved = store.savedMovies
        let watchedCount = saved.filter(store.isWatched).count
        let shown = saved.filter { shelf == .watched ? store.isWatched($0) : !store.isWatched($0) }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(saved: saved, watchedCount: watchedCount)
                picker(toWatch: saved.count - watchedCount, watched: watchedCount)

                if shown.isEmpty {
                    emptyState(hasAny: !saved.isEmpty)
                        .transition(.blurReplace)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(shown) { movie in
                            TicketStub(
                                movie: movie,
                                number: store.stubNumber(for: movie),
                                isWatched: store.isWatched(movie),
                                zoom: zoom,
                                onTear: {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { store.toggleWatched(movie) }
                                }
                            )
                            .contentShape(.rect)
                            .onTapGesture { onOpen(movie) }
                            .contextMenu {
                                Button("Open", systemImage: "arrow.up.left.and.arrow.down.right") { onOpen(movie) }
                                Button(store.isWatched(movie) ? "Mark unwatched" : "Mark watched", systemImage: "checkmark.seal") {
                                    withAnimation(.snappy) { store.toggleWatched(movie) }
                                }
                                Button("Remove stub", systemImage: "trash", role: .destructive) {
                                    withAnimation(.snappy) { store.toggleSaved(movie) }
                                }
                            }
                            .scrollTransition(.interactive) { content, phase in
                                content
                                    .opacity(phase.isIdentity ? 1 : 0.35)
                                    .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                    .rotation3DEffect(.degrees(phase.value * -22), axis: (x: 1, y: 0, z: 0))
                            }
                            .transition(AnyTransition.asymmetric(
                                insertion: AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity),
                                removal: AnyTransition.scale(scale: 0.85).combined(with: AnyTransition.opacity)
                            ))
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .animation(.snappy, value: shown.map(\.id))
        .animation(.snappy, value: shelf)
    }

    private func header(saved: [Movie], watchedCount: Int) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("stubs")
                        .font(.display(34, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    Circle()
                        .fill(Theme.ember)
                        .frame(width: 7, height: 7)
                }
                Text("\(saved.count) SAVED · \(watchedCount) SEEN")
                    .font(.mono(11, weight: .semibold))
                    .foregroundStyle(Theme.tertiaryText)
                    .contentTransition(.numericText())
            }
            Spacer()
            StampFan(movies: Array(saved.prefix(5)))
        }
        .frame(minHeight: 72)
    }

    private func picker(toWatch: Int, watched: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(Shelf.allCases) { option in
                let selected = option == shelf
                HStack(spacing: 6) {
                    Text(option.title)
                    Text(verbatim: "\(option == .toWatch ? toWatch : watched)")
                        .font(.mono(11, weight: .bold))
                        .opacity(0.6)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(selected ? Color.black : Theme.secondaryText)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background {
                    if selected {
                        Capsule()
                            .fill(.white)
                            .matchedGeometryEffect(id: "shelf", in: pill)
                    }
                }
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.32)) { shelf = option }
                }
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
        .sensoryFeedback(.selection, trigger: shelf)
    }

    private func emptyState(hasAny: Bool) -> some View {
        VStack(spacing: 14) {
            TicketPiece(side: .main, corner: 22)
                .stroke(.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.2, dash: [5, 5]))
                .frame(width: 210, height: 96)
                .overlay {
                    Image(systemName: "ticket")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Theme.tertiaryText)
                }
                .padding(.bottom, 6)
            Text(hasAny ? (shelf == .watched ? "Nothing torn yet" : "All caught up") : "No stubs yet")
                .font(.display(24))
                .foregroundStyle(Theme.primaryText)
            Text(hasAny
                 ? (shelf == .watched ? "Tear a stub once you've seen the film." : "Every stub you saved has been watched.")
                 : "Save films from the reel and they'll be printed here.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button("Browse the reel", action: onBrowse)
                .buttonStyle(.glass)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
    }
}

/// The last few saved posters, fanned like a hand of stamps.
private struct StampFan: View {
    let movies: [Movie]

    var body: some View {
        ZStack {
            ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                let spread = Double(index) - Double(movies.count - 1) / 2
                PosterView(movie: movie)
                    .frame(width: 40, height: 60)
                    .clipShape(.rect(cornerRadius: 5))
                    .padding(2.5)
                    .background(.white.opacity(0.9), in: .rect(cornerRadius: 7))
                    .rotationEffect(.degrees(spread * 9))
                    .offset(x: CGFloat(spread) * 17, y: CGFloat(abs(spread)) * 3)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    .zIndex(Double(index))
            }
        }
        .frame(width: 130, height: 72)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: movies.map(\.id))
    }
}
