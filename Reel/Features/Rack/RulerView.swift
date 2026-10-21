import SwiftUI

/// Drag to discover: every film is a tick, and a pin rides along them. The ticks swell and
/// brighten around the pin, so wherever it goes a little wave follows.
struct RulerView: View {
    let count: Int
    let motion: RackMotion

    private static let inset: CGFloat = 22
    private static let height: CGFloat = 64

    var body: some View {
        let position = motion.position
        GeometryReader { proxy in
            let width = proxy.size.width
            Canvas { context, size in
                draw(in: &context, size: size, position: position)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in motion.scrub(to: film(at: value.location.x, width: width)) }
                    .onEnded { _ in motion.endScrub() }
            )
        }
        .frame(height: Self.height)
        .accessibilityElement()
        .accessibilityLabel("Drag to discover")
        .accessibilityValue("Film \(motion.focus + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            motion.nudge(by: direction == .increment ? 1 : -1)
        }
    }

    private func film(at x: CGFloat, width: CGFloat) -> Double {
        let span = max(width - Self.inset * 2, 1)
        return Double((x - Self.inset) / span) * Double(max(count - 1, 1))
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, position: Double) {
        guard count > 1 else { return }
        let span = size.width - Self.inset * 2
        let baseline = size.height - 12
        func x(_ film: Double) -> CGFloat { Self.inset + CGFloat(film / Double(count - 1)) * span }
        let handle = x(min(max(position, 0), Double(count - 1)))

        for index in 0..<count {
            let tickX = x(Double(index))
            let swell = exp(-pow((tickX - handle) / 30, 2))
            let height = (index % 5 == 0 ? 13 : 9) + swell * 17
            let alpha = min(1, 0.3 + (tickX < handle ? 0.08 : 0) + swell * 0.62)
            context.fill(Path(CGRect(x: tickX - 0.6, y: baseline - height, width: 1.2, height: height)),
                         with: .color(.white.opacity(alpha)))
        }

        context.drawLayer { pin in
            pin.addFilter(.shadow(color: .white.opacity(0.55), radius: 5))
            pin.fill(Path(roundedRect: CGRect(x: handle - 1, y: 8, width: 2, height: baseline - 8), cornerRadius: 1), with: .color(.white))
            pin.fill(Path(ellipseIn: CGRect(x: handle - 3, y: 8 - 3, width: 6, height: 6)), with: .color(.white))
        }
    }
}
