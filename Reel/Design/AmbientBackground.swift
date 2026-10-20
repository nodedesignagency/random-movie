import SwiftUI

/// A slow-breathing mesh of light behind everything, tinted by whatever film
/// is in focus. Colour changes cross-fade instead of snapping.
struct AmbientBackground: View {
    var tint: Color

    @State private var from: Color?
    @State private var to: Color?
    @State private var changedAt = Date.distantPast

    private let fadeDuration: TimeInterval = 1.1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let current = blended(at: timeline.date)
            MeshGradient(
                width: 3,
                height: 3,
                points: Self.points(at: timeline.date.timeIntervalSinceReferenceDate),
                colors: Self.colors(tint: current)
            )
        }
        .background(Theme.night)
        .ignoresSafeArea()
        .onChange(of: tint) { _, newTint in
            let now = Date()
            from = blended(at: now)
            to = newTint
            changedAt = now
        }
    }

    private func blended(at date: Date) -> Color {
        guard let from, let to else { return tint }
        let progress = min(1, max(0, date.timeIntervalSince(changedAt) / fadeDuration))
        let eased = progress * progress * (3 - 2 * progress)
        return from.mix(with: to, by: eased)
    }

    private static func colors(tint: Color) -> [Color] {
        let night = Theme.night
        func glow(_ amount: Double) -> Color { night.mix(with: tint, by: amount) }
        return [
            glow(0.12), glow(0.24), night,
            glow(0.30), glow(0.07), glow(0.18),
            night, glow(0.40), glow(0.12),
        ]
    }

    private static func points(at time: Double) -> [SIMD2<Float>] {
        func drift(_ speed: Double, _ amplitude: Double, _ phase: Double) -> Float {
            Float(sin(time * speed + phase) * amplitude)
        }
        return [
            SIMD2(0, 0), SIMD2(0.5 + drift(0.31, 0.16, 0), 0), SIMD2(1, 0),
            SIMD2(0, 0.45 + drift(0.27, 0.12, 1)),
            SIMD2(0.5 + drift(0.23, 0.15, 2), 0.5 + drift(0.29, 0.13, 3)),
            SIMD2(1, 0.55 + drift(0.21, 0.12, 4)),
            SIMD2(0, 1), SIMD2(0.5 + drift(0.19, 0.18, 5), 1), SIMD2(1, 1),
        ]
    }
}
