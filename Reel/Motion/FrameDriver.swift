import QuartzCore

/// A display-link that calls back once per screen refresh with the elapsed
/// time, up to 120 Hz on ProMotion displays.
final class FrameDriver: NSObject {
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private let onFrame: (Double) -> Void

    init(onFrame: @escaping (Double) -> Void) {
        self.onFrame = onFrame
    }

    var isRunning: Bool { link != nil }

    func start() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
        lastTimestamp = nil
    }

    func stop() {
        link?.invalidate()
        link = nil
        lastTimestamp = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let elapsed = lastTimestamp.map { now - $0 } ?? link.duration
        lastTimestamp = now
        // Clamp so a hitch (or the first frame) can't fling the simulation.
        onFrame(min(max(elapsed, 1.0 / 240.0), 1.0 / 30.0))
    }
}
