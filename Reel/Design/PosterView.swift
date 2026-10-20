import SwiftUI

/// Just the generated artwork, filling whatever frame it's given.
struct PosterArt: View {
    let movie: Movie

    var body: some View {
        let inks = PosterArtist.Inks(movie: movie)
        let motif = movie.motif
        let seed = movie.seed
        Canvas(opaque: true) { context, size in
            PosterArtist.paint(&context, size: size, motif: motif, inks: inks, seed: seed)
        }
    }
}

/// A full poster: artwork plus typography. Give it a 2:3 frame.
struct PosterView: View {
    let movie: Movie

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack {
                PosterArt(movie: movie)

                LinearGradient(
                    colors: [movie.base.opacity(0), movie.base.mix(with: .black, by: 0.3).opacity(0.88)],
                    startPoint: UnitPoint(x: 0.5, y: 0.48),
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: String(movie.year))
                        Spacer(minLength: 4)
                        Text(movie.genres.first?.uppercased() ?? "")
                    }
                    .font(.system(size: w * 0.042, weight: .semibold, design: .monospaced))
                    .foregroundStyle(movie.ink.opacity(0.8))

                    Spacer(minLength: 0)

                    Rectangle()
                        .fill(movie.ink.opacity(0.55))
                        .frame(width: w * 0.16, height: max(1, w * 0.006))
                        .padding(.bottom, w * 0.045)

                    Text(movie.typeface.isUppercase ? movie.title.uppercased() : movie.title)
                        .font(movie.typeface.titleFont(posterWidth: w))
                        .foregroundStyle(movie.ink)
                        .lineLimit(3)
                        .minimumScaleFactor(0.4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(movie.director.uppercased())
                        .font(.system(size: w * 0.036, weight: .medium, design: .monospaced))
                        .tracking(w * 0.004)
                        .foregroundStyle(movie.ink.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.top, w * 0.03)
                }
                .padding(w * 0.075)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            }
        }
        .drawingGroup()
    }
}

#Preview {
    let store = MovieStore()
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(store.catalog.prefix(12)) { movie in
                PosterView(movie: movie)
                    .frame(width: 200, height: 300)
                    .clipShape(.rect(cornerRadius: 18))
            }
        }
        .padding()
    }
    .background(Theme.night)
}
