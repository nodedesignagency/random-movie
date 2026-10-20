import SwiftUI

/// The glass caption that rides under the reel (and the Orbit): title, credits,
/// moods, and the two things you'd do next.
struct FilmCard: View {
    let movie: Movie
    var isSaved: Bool
    var isRolling = false
    var onSave: () -> Void
    var onOpen: () -> Void

    private var contentID: String { isRolling ? "rolling" : movie.id }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if isRolling {
                    rolling
                } else {
                    details
                }
            }
            .id(contentID)
            .transition(.blurReplace)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button(action: onSave) {
                    Image(systemName: isSaved ? "ticket.fill" : "ticket")
                        .font(.system(size: 17, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(isSaved ? Theme.ember : Theme.primaryText)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.1), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved ? "Remove stub" : "Save stub")
                .sensoryFeedback(.impact(weight: .light), trigger: isSaved)

                Button(action: onOpen) {
                    Text("Open")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(.white.opacity(0.94), in: .capsule)
                }
                .buttonStyle(.plain)
            }
            .disabled(isRolling)
            .opacity(isRolling ? 0.4 : 1)
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .rect(cornerRadius: 30))
        .animation(.smooth(duration: 0.3), value: contentID)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(movie.title)
                .font(.display(24))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(verbatim: "\(movie.director) · \(movie.year) · \(movie.runtimeLabel)")
                .font(.mono(11))
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack(spacing: 5) {
                ForEach(movie.moods.prefix(2)) { mood in
                    MoodTag(mood: mood, compact: true)
                }
            }
            .padding(.top, 2)
        }
    }

    private var rolling: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "dice.fill")
                    .symbolEffect(.pulse)
                    .foregroundStyle(Theme.ember)
                Text("Rolling the reel…")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.display(23))
            .foregroundStyle(Theme.primaryText)
            Text("LET IT LAND — OR GRAB IT")
                .font(.mono(11))
                .foregroundStyle(Theme.secondaryText)
        }
    }
}
