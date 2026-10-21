import SwiftUI

/// One film, opened out of its case: the still, the logline, who made it, and what to do next.
struct MovieDetailView: View {
    let movie: Movie
    let poster: UIImage?
    let swatches: [Color]?
    let isPick: Bool
    let isSaved: Bool
    var onToggleSave: () -> Void
    var onMoreLikeThis: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            PosterBackdrop(movie: movie, poster: poster, swatches: swatches)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    content
                        .padding(.horizontal, 22)
                        .padding(.top, -70)
                        .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)

            GlassCircleButton(systemImage: "xmark", size: 44, label: "Close") { dismiss() }
                .padding(.leading, 16)
                .padding(.top, 4)
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        Color.clear
            .frame(height: 470)
            .overlay {
                AsyncImage(url: movie.backdropURL, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else if let poster {
                        Image(uiImage: poster).resizable().scaledToFill()
                    } else {
                        movie.base
                    }
                }
            }
            .clipped()
            .mask {
                LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.6), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                if isPick {
                    Label("Tonight’s pick", systemImage: "sparkle")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .glassEffect(.regular, in: .capsule)
                }
                Text(movie.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: "\(movie.year)  ·  \(movie.genres.joined(separator: " / "))  ·  \(movie.runtimeLabel)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text(movie.logline)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 18, verticalSpacing: 12) {
                fact("Director", movie.director)
                fact("Cast", movie.cast.joined(separator: ", "))
                fact("Feels", movie.moods.map(\.title).joined(separator: ", "))
            }

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: onToggleSave) {
                        Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(.white.opacity(0.9)).interactive(), in: .capsule)

                    Button(action: onMoreLikeThis) {
                        Label("More like this", systemImage: "sparkles.rectangle.stack")
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: isSaved)

            Text("Posters and stills from TMDB. This app is not endorsed or certified by TMDB.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .foregroundStyle(.white)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.42))
            Text(value)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
