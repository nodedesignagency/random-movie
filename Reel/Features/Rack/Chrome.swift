import SwiftUI

/// The film in front, set like a title card: the title, year · genre · runtime, and a badge
/// underneath when it's tonight's pick. The badge sits below so the title never moves for it.
/// While the rack is flying past, the title swaps instantly so ghosts of earlier titles never pile up.
struct TitleCard: View {
    let movie: Movie?
    let isPick: Bool
    let isPicking: Bool
    let isMoving: Bool

    var body: some View {
        VStack(spacing: 8) {
            if let movie {
                Text(movie.title)
                    .font(.system(size: movie.title.count > 20 ? 25 : 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .blur(radius: isPicking ? 5 : 0)
                    .opacity(isPicking ? 0.4 : 1)
                    .contentTransition(.opacity)

                Text(verbatim: "\(movie.year)  ·  \(movie.primaryGenre)  ·  \(movie.runtimeLabel)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .opacity(isPicking ? 0 : 1)
                    .contentTransition(.opacity)
            }
            if isPick || isPicking {
                badge
                    .padding(.top, 6)
                    .transition(AnyTransition.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.25), radius: 12, y: 2)
        .animation(isMoving ? nil : .smooth(duration: 0.3), value: movie?.id)
        .animation(.smooth(duration: 0.3), value: isPicking)
        .animation(.bouncy(duration: 0.45), value: isPick)
    }

    private var badge: some View {
        HStack(spacing: 5) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .symbolEffect(.pulse, isActive: isPicking)
            Text(isPicking ? "Picking…" : "Tonight’s pick")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .glassEffect(.regular, in: .capsule)
    }
}

/// A Liquid Glass circle with an optional dot, for the small round buttons.
struct GlassCircleButton: View {
    let systemImage: String
    var size: CGFloat = 54
    var showsDot = false
    let label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: size, height: size)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.white)
                        .frame(width: 7, height: 7)
                        .offset(x: -size * 0.2, y: size * 0.2)
                        .scaleEffect(showsDot ? 1 : 0.01)
                        .opacity(showsDot ? 1 : 0)
                        .animation(.bouncy, value: showsDot)
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(label)
    }
}

/// Save on the left, "Pick for me" in the middle, mood on the right.
struct ControlBar: View {
    let isSaved: Bool
    let hasMood: Bool
    var onSave: () -> Void
    var onPick: () -> Void
    var onMood: () -> Void

    @State private var spins = 0

    var body: some View {
        GlassEffectContainer(spacing: 24) {
            HStack(spacing: 0) {
                GlassCircleButton(systemImage: isSaved ? "bookmark.fill" : "bookmark",
                                  label: isSaved ? "Remove from your shelf" : "Save to your shelf",
                                  action: onSave)
                    .sensoryFeedback(.impact(weight: .light), trigger: isSaved)

                Spacer(minLength: 12)

                Button {
                    spins += 1
                    onPick()
                } label: {
                    Label("Pick for me", systemImage: "shuffle")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .symbolEffect(.bounce, value: spins)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 26)
                        .frame(height: 54)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.white.opacity(0.9)).interactive(), in: .capsule)

                Spacer(minLength: 12)

                GlassCircleButton(systemImage: "slider.horizontal.3", showsDot: hasMood, label: "Mood", action: onMood)
            }
        }
    }
}
