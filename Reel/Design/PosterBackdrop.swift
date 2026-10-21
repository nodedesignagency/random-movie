import SwiftUI

/// The film in front fills the whole screen: its poster's colours as a mesh gradient, edge to
/// edge, with the poster itself blurred over it for texture. Glass needs something to bend, so
/// nothing here fades to black.
struct PosterBackdrop: View {
    let movie: Movie?
    let poster: UIImage?
    let swatches: [Color]?

    private static let points: [SIMD2<Float>] = [
        [0, 0], [0.5, 0], [1, 0],
        [0, 0.45], [0.55, 0.5], [1, 0.55],
        [0, 1], [0.5, 1], [1, 1],
    ]

    private var colors: [Color] {
        if let swatches, swatches.count == 9 { return swatches }
        let fallback = (movie?.base ?? .black).mix(with: .black, by: 0.35)
        return Array(repeating: fallback, count: 9)
    }

    var body: some View {
        ZStack {
            MeshGradient(width: 3, height: 3, points: Self.points, colors: colors)

            if let poster {
                Color.clear
                    .overlay {
                        Image(uiImage: poster)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 56, opaque: true)
                    }
                    .clipped()
                    .opacity(0.42)
                    .id(movie?.id)
                    .transition(AnyTransition.opacity)
            }

            LinearGradient(colors: [.black.opacity(0.18), .clear, .clear, .black.opacity(0.32)],
                           startPoint: .top, endPoint: .bottom)
        }
        .animation(.easeInOut(duration: 0.8), value: movie?.id)
        .ignoresSafeArea()
    }
}
