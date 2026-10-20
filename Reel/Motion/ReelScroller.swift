import SwiftUI

/// Drives the reel: a continuous, wrapping position that follows the finger,
/// glides on release and settles on a card with a spring, and can play a
/// slot-machine spin that decelerates onto a chosen card.
///
/// Everything is integrated per frame (rather than handed to SwiftUI
/// animations) so the card under the centre line is always known — that's
/// what lets every card that passes tick a haptic, like a ratchet.
@Observable
final class ReelScroller {
    enum Phase: Equatable {
        case idle, dragging, settling, spinning
    }

    /// Continuous card position: integers are cards. Unbounded; wraps visually.
    private(set) var position: Double = 0 {
        didSet { syncIndex() }
    }

    /// The card nearest the centre line, wrapped into the deck. Changes only
    /// when a new card takes focus, so views can depend on it cheaply.
    private(set) var index = 0
    private(set) var phase: Phase = .idle
    /// Increments every time a spin lands.
    private(set) var landings = 0
    private(set) var count = 0

    var isSpinning: Bool { phase == .spinning }

    @ObservationIgnored private var velocity: Double = 0
    @ObservationIgnored private var target: Double = 0
    @ObservationIgnored private var dragOrigin: Double = 0
    @ObservationIgnored private var spinPlan: SpinPlan?
    @ObservationIgnored private var driver: FrameDriver?

    private struct SpinPlan {
        let from: Double
        let to: Double
        let duration: Double
        let celebrates: Bool
        var elapsed: Double = 0
    }

    // MARK: Deck

    func reset(count: Int) {
        driver?.stop()
        spinPlan = nil
        velocity = 0
        self.count = count
        phase = .idle
        position = 0
        syncIndex()
    }

    func wrap(_ i: Int) -> Int {
        count > 0 ? ((i % count) + count) % count : 0
    }

    /// Signed distance, in cards, from the centre line to card `i`, taking the short way round.
    func offset(of i: Int) -> Double {
        guard count > 0 else { return 0 }
        let n = Double(count)
        var d = (Double(i) - position).truncatingRemainder(dividingBy: n)
        if d > n / 2 { d -= n } else if d < -n / 2 { d += n }
        return d
    }

    /// Deck indices within `radius` cards of the centre, nearest first, without repeats.
    func visibleIndices(radius: Int) -> [Int] {
        guard count > 0 else { return [] }
        let base = Int(position.rounded())
        var seen = Set<Int>()
        var result: [Int] = []
        for distance in 0...radius {
            for delta in distance == 0 ? [0] : [distance, -distance] {
                let i = wrap(base + delta)
                if seen.insert(i).inserted { result.append(i) }
            }
        }
        return result
    }

    // MARK: Gestures

    func dragChanged(translation: CGFloat, spacing: CGFloat) {
        if phase != .dragging {
            driver?.stop()
            spinPlan = nil
            dragOrigin = position
            phase = .dragging
        }
        position = dragOrigin - Double(translation / spacing)
    }

    func dragEnded(velocity: CGFloat, spacing: CGFloat) {
        guard phase == .dragging else { return }
        let cardsPerSecond = -Double(velocity / spacing)
        // Project where a flick would coast to, then let a spring carry it
        // there in one continuous motion — the same trick UIScrollView paging uses.
        let projected = position + cardsPerSecond * 0.24
        settle(on: projected.rounded(), velocity: cardsPerSecond)
    }

    func scroll(toIndex destination: Int) {
        guard count > 0 else { return }
        settle(on: (position + offset(of: destination)).rounded(), velocity: velocity)
    }

    // MARK: Spinning

    /// Spins forward through at least a couple of dozen cards and decelerates onto `destination`.
    func spin(toIndex destination: Int) {
        guard count > 0 else { return }
        let current = position.rounded()
        var travel = Double(wrap(destination - wrap(Int(current))))
        while travel < 26 { travel += Double(count) }
        let duration = min(3.4, 1.7 + travel * 0.02)
        start(SpinPlan(from: position, to: current + travel, duration: duration, celebrates: true))
    }

    /// A short entrance flourish: the reel rolls up to the first card.
    func intro() {
        guard count > 1 else { return }
        position = -7
        start(SpinPlan(from: -7, to: 0, duration: 1.25, celebrates: false))
    }

    private func start(_ plan: SpinPlan) {
        spinPlan = plan
        phase = .spinning
        startDriver()
    }

    // MARK: Simulation

    private func step(_ dt: Double) {
        switch phase {
        case .spinning:
            guard var plan = spinPlan else {
                phase = .idle
                driver?.stop()
                return
            }
            plan.elapsed += dt
            let progress = min(1, plan.elapsed / plan.duration)
            // Quartic ease-out: fast start, a long dramatic crawl at the end.
            let eased = 1 - pow(1 - progress, 4)
            position = plan.from + (plan.to - plan.from) * eased
            spinPlan = plan
            if progress >= 1 {
                spinPlan = nil
                if plan.celebrates { landings += 1 }
                // A small forward kick lets the card overshoot a hair and settle, like a real reel.
                settle(on: plan.to, velocity: plan.celebrates ? 2.4 : 1.2)
            }
        case .settling:
            integrateSpring(dt)
        case .idle, .dragging:
            driver?.stop()
        }
    }

    private func settle(on destination: Double, velocity: Double) {
        target = destination
        self.velocity = velocity
        phase = .settling
        startDriver()
    }

    private func integrateSpring(_ dt: Double) {
        let response = 0.5
        let dampingRatio = 0.82
        let stiffness = pow(2 * .pi / response, 2)
        let damping = 4 * .pi * dampingRatio / response

        var x = position
        var remaining = dt
        while remaining > 0 {
            let h = min(remaining, 1.0 / 240.0)
            let acceleration = -stiffness * (x - target) - damping * velocity
            velocity += acceleration * h
            x += velocity * h
            remaining -= h
        }

        if abs(x - target) < 0.0005 && abs(velocity) < 0.01 {
            velocity = 0
            position = target
            phase = .idle
            driver?.stop()
        } else {
            position = x
        }
    }

    private func startDriver() {
        if driver == nil {
            driver = FrameDriver { [weak self] dt in self?.step(dt) }
        }
        driver?.start()
    }

    private func syncIndex() {
        let nearest = wrap(Int(position.rounded()))
        if nearest != index { index = nearest }
    }
}
