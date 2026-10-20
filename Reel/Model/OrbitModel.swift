import SwiftUI

/// The path you've taken down the rabbit hole. The last film is the one in the middle.
@Observable
final class OrbitModel {
    private(set) var trail: [Movie] = []

    var center: Movie? { trail.last }
    var depth: Int { trail.count }

    func start(at movie: Movie) {
        trail = [movie]
    }

    /// Steps into `movie`. Revisiting a film already on the trail rewinds to it
    /// instead of looping, so the trail stays a readable path.
    func dive(into movie: Movie) {
        if let index = trail.firstIndex(of: movie) {
            trail = Array(trail.prefix(through: index))
        } else {
            trail.append(movie)
        }
    }

    func back() {
        guard trail.count > 1 else { return }
        trail.removeLast()
    }
}
