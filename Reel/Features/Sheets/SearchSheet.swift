import SwiftUI

/// Find a film by title, director, actor or year, and bring it to the front of the rack.
struct SearchSheet: View {
    let films: [Movie]
    let posters: [String: UIImage]
    var onSelect: (Movie) -> Void

    @State private var query = ""

    private var results: [Movie] {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            return films.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
        return films.filter { movie in
            movie.title.localizedStandardContains(text)
                || movie.director.localizedStandardContains(text)
                || movie.cast.contains { $0.localizedStandardContains(text) }
                || String(movie.year).hasPrefix(text)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { movie in
                Button { onSelect(movie) } label: { FilmRow(movie: movie, poster: posters[movie.id]) }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.white.opacity(0.1))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay {
                if results.isEmpty { ContentUnavailableView.search(text: query) }
            }
            .navigationTitle("Find a film")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Title, director, actor or year")
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
