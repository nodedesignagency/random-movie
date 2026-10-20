import SwiftUI

/// The rabbit hole: one film in the middle, the films it connects to in orbit
/// around it. Tap a satellite and it glides to the centre while a new
/// constellation blooms out of it.
struct OrbitScreen: View {
    @Environment(MovieStore.self) private var store
    let model: OrbitModel
    let fallback: Movie?
    let zoom: Namespace.ID
    var onOpen: (Movie) -> Void

    @State private var pan: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                StarDust()
                    .offset(x: pan.width * 0.3, y: pan.height * 0.3)

                if let center = model.center {
                    let nodes = OrbitLayout.nodes(center: center, relations: store.related(to: center), in: proxy.size)
                    constellation(nodes: nodes, tint: center.glow)
                        .offset(pan)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(.rect)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Heavy resistance: the constellation leans with your finger, then floats home.
                        pan = CGSize(width: value.translation.width * 0.32, height: value.translation.height * 0.32)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { pan = .zero }
                    }
            )
        }
        .overlay(alignment: .top) { header }
        .overlay(alignment: .bottom) {
            if let center = model.center {
                FilmCard(
                    movie: center,
                    isSaved: store.isSaved(center),
                    onSave: { store.toggleSaved(center) },
                    onOpen: { onOpen(center) }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 92)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: model.center?.id)
        .onAppear {
            if model.center == nil, let fallback { model.start(at: fallback) }
        }
    }

    // MARK: Constellation

    private func constellation(nodes: [OrbitNode], tint: Color) -> some View {
        let origin = nodes.first?.point ?? .zero
        let satellites = Array(nodes.dropFirst())

        return ZStack {
            ForEach(satellites) { node in
                EdgeLine(from: origin, to: node.point)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
                    .transition(.opacity)
            }

            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(satellites) { node in
                        let progress = (time * 0.3 + node.phase).truncatingRemainder(dividingBy: 1)
                        EdgePulse(from: origin, to: node.point, progress: progress, radius: 2.4)
                            .fill(tint)
                            .shadow(color: tint, radius: 5)
                            .opacity(sin(progress * .pi) * 0.9)
                    }
                }
            }
            .allowsHitTesting(false)

            ForEach(nodes) { node in
                DriftingNode(node: node, zoom: zoom)
                    .position(node.point)
                    .zIndex(node.isCenter ? 2 : 1)
                    .transition(
                        AnyTransition.asymmetric(
                            insertion: AnyTransition.offset(x: origin.x - node.point.x, y: origin.y - node.point.y)
                                .combined(with: AnyTransition.scale(scale: 0.2))
                                .combined(with: AnyTransition.opacity),
                            removal: AnyTransition.scale(scale: 0.4).combined(with: AnyTransition.opacity)
                        )
                    )
                    .onTapGesture { select(node) }
            }
        }
    }

    private func select(_ node: OrbitNode) {
        if node.isCenter {
            onOpen(node.movie)
        } else {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.8)) {
                model.dive(into: node.movie)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("orbit")
                            .font(.display(34, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                        Circle()
                            .fill(Theme.ember)
                            .frame(width: 7, height: 7)
                    }
                    Text("DOWN THE RABBIT HOLE · DEPTH \(model.depth)")
                        .font(.mono(11, weight: .semibold))
                        .foregroundStyle(Theme.tertiaryText)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: model.depth)
                }
                Spacer()
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        if model.depth > 1 {
                            circleButton("arrow.uturn.backward", label: "Back") {
                                withAnimation(.spring(response: 0.62, dampingFraction: 0.8)) { model.back() }
                            }
                            .transition(.blurReplace)
                        }
                        circleButton("shuffle", label: "Jump somewhere related") {
                            guard let center = model.center,
                                  let next = store.related(to: center).randomElement()?.movie else { return }
                            withAnimation(.spring(response: 0.62, dampingFraction: 0.8)) { model.dive(into: next) }
                        }
                    }
                }
            }

            if model.depth > 1 {
                trail
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .animation(.snappy, value: model.depth > 1)
    }

    private var trail: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(Array(model.trail.enumerated()), id: \.element.id) { index, movie in
                        let isCurrent = index == model.trail.count - 1
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.tertiaryText)
                        }
                        Button {
                            withAnimation(.spring(response: 0.62, dampingFraction: 0.8)) { model.dive(into: movie) }
                        } label: {
                            Text(movie.title)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(isCurrent ? Color.black : Theme.secondaryText)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(isCurrent ? Color.white.opacity(0.92) : Color.white.opacity(0.08), in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .id(movie.id)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .onChange(of: model.center?.id) { _, id in
                guard let id else { return }
                withAnimation(.snappy) { reader.scrollTo(id, anchor: .trailing) }
            }
        }
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .frame(width: 46, height: 46)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}

// MARK: - Nodes

/// A node with a gentle idle float, so the constellation feels suspended in space.
private struct DriftingNode: View {
    let node: OrbitNode
    let zoom: Namespace.ID

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let amplitude: CGFloat = node.isCenter ? 0 : 4
            OrbitNodeView(node: node, zoom: zoom)
                .offset(
                    x: CGFloat(sin(t * 0.7 + node.phase * 5)) * amplitude,
                    y: CGFloat(cos(t * 0.55 + node.phase * 4)) * amplitude
                )
        }
    }
}

private struct OrbitNodeView: View {
    let node: OrbitNode
    let zoom: Namespace.ID

    var body: some View {
        let diameter = node.diameter
        PosterArt(movie: node.movie)
            .frame(width: diameter, height: diameter)
            .clipShape(.circle)
            .overlay {
                Circle().strokeBorder(.white.opacity(node.isCenter ? 0.4 : 0.2), lineWidth: node.isCenter ? 1.5 : 1)
            }
            .matchedTransitionSource(id: node.movie.id, in: zoom)
            .padding(node.isCenter ? 9 : 0)
            .background {
                Circle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .circle)
                    .opacity(node.isCenter ? 1 : 0)
            }
            .shadow(color: node.movie.glow.opacity(node.isCenter ? 0.55 : 0.25), radius: node.isCenter ? 34 : 14)
            .overlay(alignment: .top) {
                if let link = node.link {
                    caption(link)
                        .offset(y: diameter + 8)
                }
            }
            .contentShape(.circle)
    }

    private func caption(_ link: Connection) -> some View {
        VStack(spacing: 3) {
            Text(node.movie.title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            HStack(spacing: 3) {
                Image(systemName: link.symbol)
                    .font(.system(size: 8, weight: .bold))
                Text(link.label)
                    .lineLimit(1)
            }
            .font(.mono(9.5, weight: .semibold))
            .foregroundStyle(link.tint)
        }
        .frame(width: 116)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private extension Connection {
    var tint: Color {
        switch self {
        case .director: Theme.ember
        case .actor: Color(hex: "#7FD1FF")
        case .mood(let mood): mood.tint
        case .genre: Color.white.opacity(0.6)
        case .era: Color.white.opacity(0.5)
        }
    }
}

/// Faint, fixed specks of light behind the constellation.
private struct StarDust: View {
    var body: some View {
        Canvas { context, size in
            var rng = SplitMix64(seed: 0x5EED)
            var dots = Path()
            for _ in 0..<150 {
                let x = CGFloat(rng.unit()) * size.width
                let y = CGFloat(rng.unit()) * size.height
                let r = CGFloat(rng.range(0.4, 1.3))
                dots.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
            context.fill(dots, with: .color(.white.opacity(0.22)))
        }
        .allowsHitTesting(false)
    }
}
