import SwiftUI

/// Home: the reel of posters, its caption, and the filter panel that grows
/// out of the corner button.
struct ReelScreen: View {
    @Environment(MovieStore.self) private var store
    let scroller: ReelScroller
    let zoom: Namespace.ID
    @Binding var showFilters: Bool
    var onOpen: (Movie) -> Void

    @Namespace private var glass

    var body: some View {
        ZStack {
            if store.deck.isEmpty {
                emptyState
                    .transition(.blurReplace)
            } else {
                ReelStackView(deck: store.deck, scroller: scroller, zoom: zoom, onOpen: onOpen)
                    .id(store.deckVersion)
                    .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.4), value: store.deckVersion)
        .overlay(alignment: .bottom) {
            if let movie = store.movie(at: scroller.index) {
                FilmCard(
                    movie: movie,
                    isSaved: store.isSaved(movie),
                    isRolling: scroller.isSpinning,
                    onSave: { store.toggleSaved(movie) },
                    onOpen: { onOpen(movie) }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 92)
            }
        }
        .overlay {
            if showFilters {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { closeFilters() }
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .top) { header }
        .sensoryFeedback(.selection, trigger: scroller.index)
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.9), trigger: scroller.landings)
        .onChange(of: store.deckVersion) {
            scroller.reset(count: store.deck.count)
        }
        .onAppear {
            if scroller.count != store.deck.count {
                scroller.reset(count: store.deck.count)
                scroller.intro()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("reel")
                        .font(.display(34, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                    Circle()
                        .fill(Theme.ember)
                        .frame(width: 7, height: 7)
                }
                Spacer()
                if !store.deck.isEmpty {
                    HStack(spacing: 0) {
                        Text(verbatim: String(format: "%02d", scroller.index + 1))
                            .foregroundStyle(Theme.primaryText)
                        Text(verbatim: " / \(store.deck.count)")
                            .foregroundStyle(Theme.tertiaryText)
                    }
                    .font(.mono(12, weight: .semibold))
                    .monospacedDigit()
                }
            }
            .padding(.trailing, 62)
            .frame(height: 48)
            .opacity(showFilters ? 0 : 1)

            GlassEffectContainer(spacing: 24) {
                if showFilters {
                    FilterPanel(store: store, onDone: closeFilters)
                        .glassEffect(.regular, in: .rect(cornerRadius: 34))
                        .glassEffectID("filters", in: glass)
                } else {
                    Button(action: openFilters) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.primaryText)
                            .frame(width: 48, height: 48)
                            .overlay(alignment: .topTrailing) {
                                if !store.filters.isDefault {
                                    Circle()
                                        .fill(Theme.ember)
                                        .frame(width: 9, height: 9)
                                        .offset(x: -9, y: 9)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .glassEffectID("filters", in: glass)
                    .accessibilityLabel("Filters")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func openFilters() {
        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) { showFilters = true }
    }

    private func closeFilters() {
        withAnimation(.bouncy(duration: 0.45)) { showFilters = false }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "film.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.tertiaryText)
            Text("Nothing on this reel")
                .font(.display(26))
                .foregroundStyle(Theme.primaryText)
            Text("Your filters are a little too picky.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
            Button("Reset filters") {
                withAnimation(.snappy) { store.filters = Filters() }
            }
            .buttonStyle(.glass)
            .padding(.top, 6)
        }
        .padding(.bottom, 80)
    }
}
