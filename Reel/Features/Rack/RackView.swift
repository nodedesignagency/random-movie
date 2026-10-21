import SwiftUI

/// The rack of cases. Drag along it (any direction; only the part along the rack counts), tap a
/// case to bring it out, tap the one in front to open it.
struct RackView: View {
    let store: MovieStore
    let motion: RackMotion
    let shelf: CaseShelf
    let geometry: RackGeometry
    let zoom: Namespace.ID
    var onOpen: (Movie) -> Void

    @State private var isDragging = false

    var body: some View {
        let position = motion.position
        let calm = 1 - min(max((motion.speed - 5) / 15, 0), 1) * 0.8
        let introTime: Double? = motion.isEntering ? motion.introTime : nil
        let visible = visibleIndices(around: position)

        ZStack(alignment: .topLeading) {
            ForEach(visible, id: \.self) { index in
                let movie = store.films[index]
                if let image = shelf.cases[movie.id],
                   let place = geometry.placement(for: index, position: position, introTime: introTime, calm: calm) {
                    let dimmed = !store.matchesMood(movie)
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: geometry.imageSize.width, height: geometry.imageSize.height)
                        .matchedTransitionSource(id: movie.id, in: zoom)
                        .saturation(dimmed ? 0.4 : 1)
                        .brightness(dimmed ? -0.42 : 0)
                        .blur(radius: place.blur)
                        .scaleEffect(place.scale)
                        .opacity(place.opacity)
                        .position(x: place.center.x, y: place.center.y + geometry.imageOffset)
                        .zIndex(place.depth)
                        .animation(.smooth(duration: 0.5), value: dimmed)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
        .contentShape(Rectangle())
        .gesture(drag)
        .onTapGesture(coordinateSpace: .local) { tap(at: $0) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Film rack")
        .accessibilityValue(store.film(at: motion.focus)?.title ?? "")
        .accessibilityHint("Swipe up or down to move along the rack. Double-tap to open the film in front.")
        .accessibilityAdjustableAction { direction in
            motion.nudge(by: direction == .increment ? 1 : -1)
        }
        .accessibilityAction {
            if let movie = store.film(at: motion.focus) { onOpen(movie) }
        }
    }

    private func visibleIndices(around position: Double) -> [Int] {
        guard !store.films.isEmpty else { return [] }
        let lower = max(0, Int((position - Double(RackGeometry.behindRadius)).rounded(.up)))
        let upper = min(store.films.count - 1, Int((position + Double(RackGeometry.visibleRadius)).rounded(.down)))
        return lower <= upper ? Array(lower...upper) : []
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    motion.beginDrag()
                }
                motion.drag(by: geometry.films(along: value.translation))
            }
            .onEnded { value in
                isDragging = false
                motion.endDrag(velocity: geometry.films(along: value.velocity))
            }
    }

    private func tap(at point: CGPoint) {
        guard !motion.isEntering else { return }
        let position = motion.position
        let hits = visibleIndices(around: position)
            .compactMap { index -> (index: Int, depth: Double)? in
                guard let place = geometry.placement(for: index, position: position, introTime: nil, calm: 1),
                      geometry.cover(at: place.center).encloses(point) else { return nil }
                return (index, place.depth)
            }
            .sorted { $0.depth > $1.depth }
        guard let hit = hits.first else { return }
        if abs(Double(hit.index) - position) < 0.5 {
            if let movie = store.film(at: hit.index) { onOpen(movie) }
        } else {
            motion.go(to: hit.index)
        }
    }
}
