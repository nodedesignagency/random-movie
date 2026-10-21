import CoreGraphics
import Foundation

/// Where every case sits. The cases run corner to corner up an isometric diagonal; the film in
/// front slides clean out of the row along its own cover, toward you.
nonisolated struct RackGeometry {
    nonisolated struct Placement {
        var center: CGPoint
        var scale: CGFloat
        var opacity: Double
        /// Depth of field: cases far along the rack, near the screen's edges, go soft.
        var blur: CGFloat
        /// Nearer cases (later in the rack) draw on top.
        var depth: Double
    }

    let size: CGSize
    let caseWidth: CGFloat
    let caseHeight: CGFloat
    /// The cover's width as a vector: the direction a case slides when it comes out of the row.
    let slide: CGVector
    /// One film's spacing up the rack.
    let step: CGVector
    let stepLength: CGFloat
    /// Where the film in front would sit if it stayed in the row.
    let anchor: CGPoint

    /// How many cases show in front of (down-left of) the film in front, and behind it (up-right).
    /// The run behind is short so the rack ends below the title instead of under it.
    static let visibleRadius = 15
    static let behindRadius = 7

    init(size: CGSize) {
        self.size = size
        caseWidth = min(size.width * 0.47, 220)
        caseHeight = caseWidth * CaseTemplate.aspect
        let tl = CaseTemplate.insertTopLeft
        let tr = CaseTemplate.insertTopRight
        slide = CGVector(dx: (tr.x - tl.x) * caseWidth, dy: (tr.y - tl.y) * caseHeight)
        stepLength = caseWidth * 0.18
        let angle = 38.0 * Double.pi / 180
        step = CGVector(dx: cos(angle) * stepLength, dy: -sin(angle) * stepLength)
        anchor = CGPoint(x: size.width * 0.5 - slide.dx * 0.42, y: min(size.height * 0.52, size.height - 380))
    }

    /// The rendered case image is larger than the case itself: it carries its shadow.
    var imageSize: CGSize {
        let margins = CaseMargins.shadow
        return CGSize(width: caseWidth * (1 + margins.side * 2), height: caseHeight + caseWidth * (margins.top + margins.bottom))
    }

    /// From the case's centre to the centre of its shadowed image.
    var imageOffset: CGFloat {
        let margins = CaseMargins.shadow
        return (margins.bottom - margins.top) * caseWidth / 2
    }

    /// `introTime` is nil once the entrance is over. `calm` (0…1) shrinks the pull-out while the
    /// rack is moving fast, so cases only peek out as they fly past.
    func placement(for index: Int, position: Double, introTime: Double?, calm: Double) -> Placement? {
        let d = Double(index) - position
        let distance = abs(d)
        guard d <= Double(Self.visibleRadius), d >= -Double(Self.behindRadius) else { return nil }

        var pull = smoothstep(1 - distance) * calm
        var x = anchor.x - d * step.dx
        var y = anchor.y - d * step.dy
        var opacity = 1.0
        var scale = 1.0

        if let time = introTime {
            // A ribbon sweeps in from the lower right and lays each case into its slot, far end first.
            let order = (d + Double(Self.behindRadius)) / Double(Self.behindRadius + Self.visibleRadius)
            let progress = clamp01((time - order * 0.9) / 0.8)
            let eased = 1 - pow(1 - progress, 3)
            let start = CGPoint(x: x + size.width * 0.95, y: y + size.height * 0.32)
            let control = CGPoint(x: x + size.width * 0.55, y: y - size.height * 0.12)
            let inverse = 1 - eased
            x = inverse * inverse * start.x + 2 * inverse * eased * control.x + eased * eased * x
            y = inverse * inverse * start.y + 2 * inverse * eased * control.y + eased * eased * y
            opacity = clamp01(progress * 3)
            scale = 0.92 + 0.08 * eased
            pull *= smoothstep(clamp01((time - 1.45) / 0.45))
        }

        x += slide.dx * pull
        y += slide.dy * pull - pull * caseHeight * 0.02
        // The far end dissolves case by case; the near end, running under the controls, goes soft.
        opacity *= clamp01((d + Double(Self.behindRadius)) / 2.5)
        let blur = (min(5, max(0, d - 5) * 0.8) * 2).rounded() / 2
        return Placement(center: CGPoint(x: x, y: y), scale: scale, opacity: opacity, blur: blur, depth: d)
    }

    /// The cover insert's outline for a case centred at `center`, for hit testing.
    func cover(at center: CGPoint) -> [CGPoint] {
        let origin = CGPoint(x: center.x - caseWidth / 2, y: center.y - caseHeight / 2)
        return [CaseTemplate.insertTopLeft, CaseTemplate.insertTopRight, CaseTemplate.insertBottomRight, CaseTemplate.insertBottomLeft]
            .map { CGPoint(x: origin.x + $0.x * caseWidth, y: origin.y + $0.y * caseHeight) }
    }

    /// Converts a finger movement into films travelled along the rack.
    func films(along translation: CGSize) -> Double {
        let along = (translation.width * step.dx + translation.height * step.dy) / stepLength
        return along / (stepLength * 1.25)
    }

    private func clamp01(_ value: Double) -> Double { min(1, max(0, value)) }
    private func smoothstep(_ value: Double) -> Double {
        let t = clamp01(value)
        return t * t * (3 - 2 * t)
    }
}

nonisolated extension Array where Element == CGPoint {
    /// Even-odd point-in-polygon test.
    func encloses(_ point: CGPoint) -> Bool {
        var inside = false
        var j = count - 1
        for i in indices {
            let a = self[i], b = self[j]
            if (a.y > point.y) != (b.y > point.y),
               point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}
