import SwiftUI

/// Full-screen film page. Presented with a zoom transition out of whichever
/// poster you tapped, and swipe-down to dismiss back into it.
struct MovieDetailView: View {
    let movie: Movie
    var onOrbit: (Movie) -> Void

    @Environment(MovieStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            AmbientBackground(tint: movie.glow)
            GrainOverlay()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PosterView(movie: movie)
                        .frame(width: 250, height: 375)
                        .clipShape(.rect(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: movie.glow.opacity(0.45), radius: 40, y: 20)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 72)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(movie.title)
                            .font(.display(38, weight: .bold))
                            .foregroundStyle(Theme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: "\(movie.year) · \(movie.runtimeLabel) · \(movie.genres.joined(separator: " / "))".uppercased())
                            .font(.mono(12, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }

                    Text(movie.logline)
                        .font(.system(size: 19, weight: .regular, design: .serif))
                        .foregroundStyle(Theme.primaryText.opacity(0.88))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        ForEach(movie.moods) { mood in
                            MoodTag(mood: mood)
                        }
                    }

                    credits

                    actions
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)

            topBar
        }
        .preferredColorScheme(.dark)
    }

    private var credits: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                label("DIRECTED BY")
                Text(movie.director)
                    .font(.display(22))
                    .foregroundStyle(Theme.primaryText)
            }
            VStack(alignment: .leading, spacing: 8) {
                label("STARRING")
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(movie.cast, id: \.self) { name in
                            Text(name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.primaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.08), in: .capsule)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var actions: some View {
        let saved = store.isSaved(movie)
        return GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) { store.toggleSaved(movie) }
                } label: {
                    Label(saved ? "Saved" : "Save stub", systemImage: saved ? "ticket.fill" : "ticket")
                        .font(.system(size: 16, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glass)
                .sensoryFeedback(.impact(weight: .light), trigger: saved)

                Button {
                    onOrbit(movie)
                } label: {
                    Label("Rabbit hole", systemImage: "point.3.filled.connected.trianglepath.dotted")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.ember)
            }
        }
        .padding(.top, 8)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("Close")

            Spacer()

            ShareLink(item: "Tonight’s pick: \(movie.title) (\(movie.year)), dir. \(movie.director). Rolled on Reel.") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.mono(11, weight: .semibold))
            .tracking(1.5)
            .foregroundStyle(Theme.tertiaryText)
    }
}
