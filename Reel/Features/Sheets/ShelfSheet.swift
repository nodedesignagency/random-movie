import SwiftUI

/// The films you've kept. Tap one to bring it to the front of the rack; swipe to let it go.
struct ShelfSheet: View {
    let store: MovieStore
    let posters: [String: UIImage]
    var onSelect: (Movie) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your shelf")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Spacer()
                Text("\(store.savedMovies.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)

            if store.savedMovies.isEmpty {
                ContentUnavailableView("Nothing on your shelf yet",
                                       systemImage: "bookmark",
                                       description: Text("Tap the bookmark under the rack to keep a film here."))
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.savedMovies) { movie in
                        Button { onSelect(movie) } label: { FilmRow(movie: movie, poster: posters[movie.id]) }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(.white.opacity(0.1))
                    }
                    .onDelete { store.removeSaved(at: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// A film in a list: poster thumbnail, title, director and year.
struct FilmRow: View {
    let movie: Movie
    let poster: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let poster {
                    Image(uiImage: poster).resizable().scaledToFill()
                } else {
                    movie.base
                }
            }
            .frame(width: 44, height: 66)
            .clipShape(.rect(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(movie.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(verbatim: "\(movie.director) · \(movie.year)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }
}
