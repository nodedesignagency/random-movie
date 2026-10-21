import Foundation
import Observation

/// The rack's physics. `position` is measured in films (0 is the first case) and is what every
/// view reads; the rest is how it gets anywhere: the entrance, your finger, the ruler, a spring,
/// or a timed spin for "Pick for me". The rack has two ends, like a real shelf, and gives a
/// little if you pull past them.
@Observable
final class RackMotion {
    enum Phase: Equatable { case waiting, intro, idle, drag, scrub, settle, spin }

    /// Posted when a spin arrives, so the screen can crown a new pick.
    struct Landing: Equatable {
        let serial: Int
        let index: Int
        let isPick: Bool
    }

    private(set) var position: Double = 0
    private(set) var phase: Phase = .waiting
    private(set) var introTime: Double = 0
    /// Smoothed speed in films per second. Cases only peek out of the row while you fly past.
    private(set) var speed: Double = 0
    /// The film in front when "Pick for me" started; the title holds it while the rack spins.
    private(set) var pickingFrom: Int?
    private(set) var landing: Landing?

    static let introDuration = 2.0

    @ObservationIgnored private(set) var count = 0
    @ObservationIgnored private var velocity = 0.0
    @ObservationIgnored private var target = 0.0
    @ObservationIgnored private var scrubTarget = 0.0
    @ObservationIgnored private var dragOrigin = 0.0
    @ObservationIgnored private var spin: Spin?
    @ObservationIgnored private var landings = 0
    @ObservationIgnored private var frozen = false
    @ObservationIgnored private var driver: FrameDriver?

    private struct Spin {
        let from: Double
        let to: Double
        let duration: Double
        var elapsed = 0.0
        let isPick: Bool
    }

    var focus: Int { clampIndex(Int(position.rounded())) }
    var isPicking: Bool { pickingFrom != nil }
    var isEntering: Bool { phase == .waiting || phase == .intro }

    // MARK: Setup

    func configure(count: Int, start: Int) {
        self.count = count
        position = Double(clampIndex(start))
        target = position
    }

    func playIntro() {
        introTime = 0
        phase = .intro
        run()
    }

    func skipIntro() {
        introTime = Self.introDuration
        phase = .idle
    }

    /// Freezes the entrance at one moment, for inspecting it.
    func pose(introAt time: Double) {
        frozen = true
        introTime = time
        phase = .intro
    }

    // MARK: Your finger on the rack

    func beginDrag() {
        guard canInteract else { return }
        cancelSpin()
        dragOrigin = position
        velocity = 0
        phase = .drag
        run()
    }

    /// `films` is how far the finger has travelled along the rack since `beginDrag`, in films.
    func drag(by films: Double) {
        guard phase == .drag else { return }
        position = band(dragOrigin + films)
    }

    /// `velocity` in films per second; the rack coasts on it and lands on the nearest case.
    func endDrag(velocity: Double) {
        guard phase == .drag else { return }
        target = Double(clampIndex(Int((position + velocity * 0.24).rounded())))
        self.velocity = velocity
        phase = .settle
        run()
    }

    // MARK: The ruler

    func scrub(to film: Double) {
        guard canInteract else { return }
        if phase != .scrub {
            cancelSpin()
            velocity = 0
        }
        scrubTarget = min(max(film, 0), lastIndex)
        phase = .scrub
        run()
    }

    func endScrub() {
        guard phase == .scrub else { return }
        target = scrubTarget.rounded()
        phase = .settle
        run()
    }

    // MARK: Going places

    func nudge(by step: Int) {
        guard canInteract else { return }
        cancelSpin()
        let from = phase == .settle ? target : position.rounded()
        target = Double(clampIndex(Int(from) + step))
        phase = .settle
        run()
    }

    /// Nearby films are a spring away; distant ones get a short spin.
    func go(to index: Int) {
        guard canInteract else { return }
        cancelSpin()
        let distance = Double(clampIndex(index)) - position.rounded()
        if abs(distance) <= 6 {
            target = Double(clampIndex(index))
            phase = .settle
        } else {
            spin = Spin(from: position, to: Double(clampIndex(index)), duration: min(1.6, 0.7 + abs(distance) * 0.03), isPick: false)
            phase = .spin
        }
        run()
    }

    /// "Pick for me": a longer, decelerating run that lands on `index` and crowns it.
    func pick(_ index: Int) {
        guard canInteract else { return }
        cancelSpin()
        let to = Double(clampIndex(index))
        spin = Spin(from: position, to: to, duration: min(2.6, 1.1 + abs(to - position) * 0.045), isPick: true)
        pickingFrom = focus
        phase = .spin
        run()
    }

    // MARK: Frame loop

    private var canInteract: Bool { !isEntering && count > 0 }
    private var lastIndex: Double { Double(max(count - 1, 0)) }

    private func clampIndex(_ index: Int) -> Int { min(max(index, 0), max(count - 1, 0)) }

    private func cancelSpin() {
        guard spin != nil else { return }
        spin = nil
        pickingFrom = nil
    }

    private func run() {
        if driver == nil {
            driver = FrameDriver { [weak self] elapsed in self?.step(elapsed) }
        }
        driver?.start()
    }

    private func step(_ dt: Double) {
        guard !frozen else { return }
        let before = position
        switch phase {
        case .waiting, .idle, .drag:
            break
        case .intro:
            introTime = min(introTime + dt, Self.introDuration)
            if introTime >= Self.introDuration { phase = .idle }
        case .scrub:
            // Stiff and critically damped: the rack keeps up with the handle without wobbling.
            spring(toward: scrubTarget, response: 0.2, damping: 1, dt: dt)
        case .settle:
            spring(toward: target, response: 0.55, damping: 0.84, dt: dt)
            if abs(position - target) < 5e-4, abs(velocity) < 0.01 {
                position = target
                velocity = 0
                phase = .idle
            }
        case .spin:
            guard var current = spin else {
                phase = .idle
                break
            }
            current.elapsed += dt
            let progress = min(1, current.elapsed / current.duration)
            position = current.from + (current.to - current.from) * (1 - pow(1 - progress, 4))
            spin = current
            if progress >= 1 { land(current) }
        }
        speed = speed * 0.85 + abs(position - before) / max(dt, 1e-3) * 0.15
        if phase == .idle {
            speed = 0
            driver?.stop()
        }
    }

    private func spring(toward goal: Double, response: Double, damping: Double, dt: Double) {
        let stiffness = pow(2 * .pi / response, 2)
        let friction = 4 * .pi * damping / response
        var remaining = dt
        while remaining > 0 {
            let h = min(remaining, 1.0 / 240)
            velocity += (-stiffness * (position - goal) - friction * velocity) * h
            position += velocity * h
            remaining -= h
        }
    }

    private func land(_ finished: Spin) {
        spin = nil
        target = finished.to
        velocity = finished.to >= finished.from ? 1.6 : -1.6     // a small overshoot, so it lands rather than stops
        phase = .settle
        pickingFrom = nil
        landings += 1
        landing = Landing(serial: landings, index: Int(finished.to), isPick: finished.isPick)
    }

    /// Past either end the rack gives a little, then resists.
    private func band(_ value: Double) -> Double {
        func rubber(_ overshoot: Double) -> Double { (1 - 1 / (overshoot * 0.6 + 1)) / 0.6 }
        if value < 0 { return -rubber(-value) }
        if value > lastIndex { return lastIndex + rubber(value - lastIndex) }
        return value
    }
}
