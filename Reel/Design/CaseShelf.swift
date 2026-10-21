import SwiftUI
import UIKit

/// Builds every film's case in the background, nearest the starting film first, and keeps the
/// results: the rendered case, the poster itself, and the poster's colours for the backdrop.
@Observable
final class CaseShelf {
    private(set) var cases: [String: UIImage] = [:]
    private(set) var posters: [String: UIImage] = [:]
    private(set) var swatches: [String: [RGB]] = [:]
    /// True once every case that's on screen at the start has been built.
    private(set) var isReady = false

    @ObservationIgnored private var started = false

    func prepare(_ films: [Movie], around center: Int, onScreen radius: Int = 16) async {
        guard !started else { return }
        started = true

        let template = await Task.detached(priority: .userInitiated) { CaseTemplate.load() }.value
        guard let template else {
            assertionFailure("The case template layers are missing from the app bundle")
            isReady = true
            return
        }

        let order = films.indices.sorted { abs($0 - center) < abs($1 - center) }
        let firstWave = Set(order.prefix(radius * 2 + 1).map { films[$0].id })
        var pending = firstWave
        var jobs = order.map { films[$0] }.makeIterator()

        await withTaskGroup(of: Built?.self) { group in
            for _ in 0..<4 {
                if let movie = jobs.next() { group.addTask { Self.build(movie, template: template) } }
            }
            while let built = await group.next() {
                if let built {
                    cases[built.id] = built.caseImage
                    posters[built.id] = built.poster
                    swatches[built.id] = built.swatches
                    pending.remove(built.id)
                }
                if !isReady, pending.isEmpty { isReady = true }
                if let movie = jobs.next() { group.addTask { Self.build(movie, template: template) } }
            }
        }
        isReady = true
    }

    nonisolated private struct Built: @unchecked Sendable {   // immutable images
        let id: String
        let caseImage: UIImage
        let poster: UIImage
        let swatches: [RGB]
    }

    nonisolated private static func build(_ movie: Movie, template: CaseTemplate) -> Built? {
        let name = movie.bundledPosterName
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg")
                ?? Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "Posters"),
              let poster = CaseArt.loadImage(url),
              let caseImage = CaseArt.render(movie, poster: poster, template: template) else { return nil }
        return Built(id: movie.id,
                     caseImage: UIImage(cgImage: caseImage),
                     poster: UIImage(cgImage: poster),
                     swatches: CaseArt.swatches(of: poster))
    }
}
