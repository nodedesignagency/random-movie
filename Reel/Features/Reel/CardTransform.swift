import CoreGraphics
import Foundation

/// Where a card sits on the reel, given its distance from the centre line.
///
/// The centre card faces you; neighbours fold back like a Rolodex drum and
/// stack into ever-thinner slivers above and below. Every value is a smooth
/// function of the offset (no kinks), so cards never hitch as they travel.
nonisolated struct CardTransform {
    /// Rotation about the horizontal axis, in degrees. Positive tips the top edge away.
    let angle: Double
    /// Vertical offset from the centre line.
    let y: CGFloat
    let scale: CGFloat
    /// Darkening (0…1) for cards turned away from the light.
    let shade: Double
    let opacity: Double
    /// 0 when facing you, 1 once fully folded.
    let fold: Double
    let zIndex: Double
    /// Half of the card's on-screen height after folding, for hit testing.
    let projectedHalfHeight: CGFloat

    init(offset d: Double, cardHeight: CGFloat) {
        let distance = abs(d)
        let sign: Double = d < 0 ? -1 : 1
        let near = min(distance, 1)
        let beyond = max(distance - 1, 0)

        let fold = near * near * (3 - 2 * near)
        self.fold = fold

        // Cubic Hermite from the centre to the first fold: leaves the centre quickly and
        // arrives with exactly the slope of the sliver stack, so motion stays continuous.
        let firstGap = Double(cardHeight) * 0.5 + 30
        let sliver = 34.0
        let decay = 0.9
        let tailSlope = sliver * -log(decay) / (1 - decay)
        let s0 = 1.7
        let s1 = tailSlope / firstGap
        let a = near
        let hermite = (a * a * a - 2 * a * a + a) * s0 + (-2 * a * a * a + 3 * a * a) + (a * a * a - a * a) * s1
        let tail = sliver * (1 - pow(decay, beyond)) / (1 - decay)
        y = CGFloat(sign * (firstGap * hermite + tail))

        let tilt = min(66 * fold + 1.5 * beyond, 74)
        angle = -sign * tilt

        // Folding swings the near edge toward the camera, which perspective magnifies;
        // shrinking folded cards cancels that so the drum recedes instead of flaring.
        let rawScale = 1.035 - 0.2 * fold - 0.022 * beyond
        scale = CGFloat(max(rawScale, 0.68))
        shade = min(0.36 * fold + 0.07 * beyond, 0.78)

        let fadeStart = 4.4
        let fadeEnd = 6.8
        let f = min(max((distance - fadeStart) / (fadeEnd - fadeStart), 0), 1)
        opacity = 1 - f * f * (3 - 2 * f)

        zIndex = -distance
        projectedHalfHeight = cardHeight * 0.5 * scale * CGFloat(cos(tilt * .pi / 180))
    }
}
