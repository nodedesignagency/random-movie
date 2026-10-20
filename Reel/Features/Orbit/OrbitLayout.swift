import SwiftUI

/// A film placed in the constellation.
nonisolated struct OrbitNode: Identifiable {
    let movie: Movie
    let link: Connection?
    let point: CGPoint
    let diameter: CGFloat
    /// Stagger for idle drift and edge pulses, so nothing moves in lockstep.
    let phase: Double

    var id: String { movie.id }
    var isCenter: Bool { link == nil }
}

nonisolated enum OrbitLayout {
    static let centerDiameter: CGFloat = 148
    static let satelliteDiameter: CGFloat = 76

    /// Centre film in the middle, related films on a slightly irregular ring.
    /// The jitter is seeded by the centre film, so each constellation has its
    /// own shape but never reshuffles while you look at it.
    static func nodes(center: Movie, relations: [Relation], in size: CGSize) -> [OrbitNode] {
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.42)
        let radiusX = min(size.width * 0.37, 160)
        let radiusY = min(size.height * 0.24, radiusX * 1.12)
        var rng = SplitMix64(seed: center.seed)
        let start = -Double.pi / 2 + rng.range(-0.35, 0.35)

        var nodes = [OrbitNode(movie: center, link: nil, point: origin, diameter: centerDiameter, phase: 0)]
        for (k, relation) in relations.enumerated() {
            let angle = start + Double(k) / Double(max(relations.count, 1)) * 2 * .pi + rng.range(-0.16, 0.16)
            let stretch = CGFloat(rng.range(0.9, 1.06))
            let point = CGPoint(
                x: origin.x + CGFloat(cos(angle)) * radiusX * stretch,
                y: origin.y + CGFloat(sin(angle)) * radiusY * stretch
            )
            nodes.append(OrbitNode(movie: relation.movie, link: relation.link, point: point, diameter: satelliteDiameter, phase: Double(k) * 0.37))
        }
        return nodes
    }
}

/// A straight edge whose endpoints animate, so lines follow their nodes when the constellation re-forms.
nonisolated struct EdgeLine: Shape {
    var from: CGPoint
    var to: CGPoint

    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(from.animatableData, to.animatableData) }
        set {
            from.animatableData = newValue.first
            to.animatableData = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

/// A dot travelling along an edge. Endpoints animate like `EdgeLine`; `progress`
/// is driven per frame and deliberately not animatable.
nonisolated struct EdgePulse: Shape {
    var from: CGPoint
    var to: CGPoint
    var progress: Double
    var radius: CGFloat

    var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get { AnimatablePair(from.animatableData, to.animatableData) }
        set {
            from.animatableData = newValue.first
            to.animatableData = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let t = CGFloat(progress)
        let point = CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t)
        return Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }
}
