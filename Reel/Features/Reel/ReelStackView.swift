import SwiftUI

/// The 3D reel of posters. Drag to scroll with momentum, tap a card to bring
/// it to the centre, tap the centre card to open it.
struct ReelStackView: View {
    let deck: [Movie]
    let scroller: ReelScroller
    let zoom: Namespace.ID
    var onOpen: (Movie) -> Void

    /// Finger travel, in points, that advances the reel by one card.
    private let spacing: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cardWidth = min(size.width * 0.6, 270)
            let cardHeight = cardWidth * 1.5
            let centerY = size.height * 0.44
            let indices = scroller.visibleIndices(radius: 7).filter { deck.indices.contains($0) }

            ZStack {
                if let focused = deck.indices.contains(scroller.index) ? deck[scroller.index] : nil {
                    LandingGlow(color: focused.glow, landings: scroller.landings)
                        .frame(width: cardWidth * 0.95, height: cardHeight * 0.85)
                        .position(x: size.width / 2, y: centerY + 12)
                        .zIndex(-100)
                }

                ForEach(indices, id: \.self) { i in
                    let transform = CardTransform(offset: scroller.offset(of: i), cardHeight: cardHeight)
                    ReelCard(movie: deck[i], transform: transform, width: cardWidth, zoom: zoom)
                        .position(x: size.width / 2, y: centerY + transform.y)
                        .zIndex(transform.zIndex)
                }
            }
            .keyframeAnimator(initialValue: 1.0, trigger: scroller.landings) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.035, duration: 0.14, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.6, spring: .bouncy)
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        scroller.dragChanged(translation: value.translation.height, spacing: spacing)
                    }
                    .onEnded { value in
                        scroller.dragEnded(velocity: value.velocity.height, spacing: spacing)
                    }
            )
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    handleTap(at: value.location, in: size, centerY: centerY, cardWidth: cardWidth, cardHeight: cardHeight, indices: indices)
                }
            )
        }
    }

    /// Nearer cards sit on top, so the first card (nearest-first) whose folded
    /// extent contains the tap is the one the finger actually landed on.
    private func handleTap(at point: CGPoint, in size: CGSize, centerY: CGFloat, cardWidth: CGFloat, cardHeight: CGFloat, indices: [Int]) {
        guard abs(point.x - size.width / 2) < cardWidth * 0.55 else { return }
        let dy = point.y - centerY
        let candidates = indices
            .map { (index: $0, offset: scroller.offset(of: $0)) }
            .sorted { abs($0.offset) < abs($1.offset) }
        for candidate in candidates {
            let transform = CardTransform(offset: candidate.offset, cardHeight: cardHeight)
            guard abs(dy - transform.y) <= transform.projectedHalfHeight else { continue }
            if abs(candidate.offset) < 0.5, !scroller.isSpinning {
                onOpen(deck[candidate.index])
            } else {
                scroller.scroll(toIndex: candidate.index)
            }
            return
        }
    }
}

private struct ReelCard: View {
    let movie: Movie
    let transform: CardTransform
    let width: CGFloat
    let zoom: Namespace.ID

    var body: some View {
        let radius = width * 0.075
        PosterView(movie: movie)
            .frame(width: width, height: width * 1.5)
            .overlay(Color.black.opacity(transform.shade))
            .clipShape(.rect(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08 + 0.18 * (1 - transform.fold)), lineWidth: 0.8)
            }
            .matchedTransitionSource(id: movie.id, in: zoom)
            .scaleEffect(transform.scale)
            .rotation3DEffect(
                .degrees(transform.angle),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.45
            )
            .opacity(transform.opacity)
    }
}

/// Soft coloured light behind the centre card that flares when a spin lands.
private struct LandingGlow: View {
    let color: Color
    let landings: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 60, style: .continuous)
            .fill(color)
            .blur(radius: 55)
            .animation(.smooth(duration: 0.6), value: color)
            .keyframeAnimator(initialValue: GlowPulse(), trigger: landings) { content, pulse in
                content
                    .scaleEffect(pulse.scale)
                    .opacity(pulse.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(1.3, duration: 0.25, spring: .snappy)
                    SpringKeyframe(1.0, duration: 1.0, spring: .smooth)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.95, duration: 0.15)
                    CubicKeyframe(0.42, duration: 1.1)
                }
            }
    }
}

private nonisolated struct GlowPulse {
    var scale = 1.0
    var opacity = 0.42
}
