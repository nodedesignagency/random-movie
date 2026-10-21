import SwiftUI

/// The film in front fills the whole screen: a 4×4 mesh of its poster's colours, edge to edge,
/// so the glass always has colour to bend.
///
/// The blend is driven frame by frame rather than by SwiftUI animations: every new film retargets
/// from whatever is on screen right now, so however fast the rack moves, the colours glide.
struct PosterBackdrop: View {
    /// Identifies the colours; the blend restarts whenever it changes.
    let key: String?
    let palette: [RGB]?
    var fallback = RGB(red: 0.05, green: 0.05, blue: 0.06)

    @State private var from: [RGB] = []
    @State private var to: [RGB] = []
    @State private var start = Date.distantPast
    @State private var isBlending = false

    private static let duration = 0.9
    private static let side = CaseArt.swatchGrid

    /// Interior points nudged off the grid so the colour fields look poured, not tiled.
    private static let points: [SIMD2<Float>] = (0..<side).flatMap { row in
        (0..<side).map { column in
            let x = Float(column) / Float(side - 1)
            let y = Float(row) / Float(side - 1)
            let interior = row > 0 && row < side - 1 && column > 0 && column < side - 1
            let wobble: Float = interior ? ((row + column) % 2 == 0 ? 0.05 : -0.05) : 0
            return SIMD2(x + wobble, y - wobble * 0.6)
        }
    }

    private var target: [RGB] {
        if let palette, palette.count == Self.side * Self.side {
            return palette
        }
        return Array(repeating: fallback, count: Self.side * Self.side)
    }

    var body: some View {
        TimelineView(.animation(paused: !isBlending)) { timeline in
            MeshGradient(width: Self.side, height: Self.side, points: Self.points,
                         colors: colors(at: timeline.date).map(\.color))
        }
        .overlay {
            LinearGradient(colors: [.black.opacity(0.2), .clear, .clear, .black.opacity(0.3)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
        .onChange(of: BlendKey(key: key, hasPalette: palette != nil), initial: true) { _, _ in
            retarget()
        }
    }

    private struct BlendKey: Equatable {
        let key: String?
        let hasPalette: Bool
    }

    private func colors(at date: Date) -> [RGB] {
        guard !from.isEmpty, from.count == to.count else { return to.isEmpty ? target : to }
        let t = min(max(date.timeIntervalSince(start) / Self.duration, 0), 1)
        let eased = 1 - pow(1 - t, 3)
        return zip(from, to).map { $0.mixed(with: $1, by: eased) }
    }

    private func retarget() {
        let now = Date()
        let next = target
        guard !to.isEmpty else {
            from = next
            to = next
            return
        }
        from = colors(at: now)
        to = next
        start = now
        isBlending = true
        Task {
            try? await Task.sleep(for: .seconds(Self.duration + 0.05))
            if Date().timeIntervalSince(start) >= Self.duration { isBlending = false }
        }
    }
}
