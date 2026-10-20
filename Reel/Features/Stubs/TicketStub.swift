import SwiftUI

/// One half of a ticket. Each half is cut with quarter-circle notches on the
/// shared edge, so together they read as a perforated ticket and apart they
/// read as a torn one.
nonisolated struct TicketPiece: Shape {
    enum Side { case main, stub }

    var side: Side
    var notch: CGFloat = 9
    var corner: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        let base: Path
        let edgeX: CGFloat
        switch side {
        case .main:
            base = UnevenRoundedRectangle(
                topLeadingRadius: corner, bottomLeadingRadius: corner,
                bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous
            ).path(in: rect)
            edgeX = rect.maxX
        case .stub:
            base = UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 0,
                bottomTrailingRadius: corner, topTrailingRadius: corner, style: .continuous
            ).path(in: rect)
            edgeX = rect.minX
        }
        var notches = Path()
        notches.addEllipse(in: CGRect(x: edgeX - notch, y: rect.minY - notch, width: notch * 2, height: notch * 2))
        notches.addEllipse(in: CGRect(x: edgeX - notch, y: rect.maxY - notch, width: notch * 2, height: notch * 2))
        return base.subtracting(notches)
    }
}

nonisolated struct Perforation: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 12))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 12))
        return path
    }
}

/// A saved film printed as a liquid-glass ticket. Tap the stub to tear it off
/// (mark as watched); tap it again to tape it back.
struct TicketStub: View {
    let movie: Movie
    let number: Int
    let isWatched: Bool
    let zoom: Namespace.ID
    var onTear: () -> Void

    private let height: CGFloat = 134

    var body: some View {
        HStack(spacing: 0) {
            main
            stub
                .frame(width: 82)
                .offset(x: isWatched ? 12 : 0, y: isWatched ? 8 : 0)
                .rotationEffect(.degrees(isWatched ? 8 : 0), anchor: .bottomLeading)
        }
        .frame(height: height)
        .animation(.spring(response: 0.45, dampingFraction: 0.58), value: isWatched)
        .sensoryFeedback(.impact(weight: .medium), trigger: isWatched)
    }

    private var main: some View {
        HStack(spacing: 14) {
            PosterView(movie: movie)
                .frame(width: 70, height: 105)
                .clipShape(.rect(cornerRadius: 10, style: .continuous))
                .matchedTransitionSource(id: movie.id, in: zoom)

            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: "ADMIT ONE · Nº \(String(format: "%04d", number))")
                    .font(.mono(9.5, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(movie.glow)
                Text(movie.title)
                    .font(.display(20))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(movie.director)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                Text(verbatim: "\(movie.year) · \(movie.runtimeLabel)")
                    .font(.mono(11))
                    .foregroundStyle(Theme.tertiaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(movie.base.opacity(0.32)), in: TicketPiece(side: .main))
        .overlay(alignment: .topTrailing) {
            if isWatched {
                WatchedStamp(color: movie.glow)
                    .padding(.top, 12)
                    .padding(.trailing, 10)
                    .transition(.scale(scale: 1.8).combined(with: .opacity))
            }
        }
    }

    private var stub: some View {
        VStack(spacing: 4) {
            Text("Nº")
                .font(.mono(9, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
            Text(verbatim: String(format: "%04d", number))
                .font(.mono(14, weight: .bold))
                .foregroundStyle(Theme.primaryText)
            Spacer(minLength: 0)
            Image(systemName: isWatched ? "checkmark.seal.fill" : "scissors")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isWatched ? movie.glow : Theme.secondaryText)
                .contentTransition(.symbolEffect(.replace))
            Text(isWatched ? "SEEN" : "TEAR")
                .font(.mono(9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Theme.tertiaryText)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular.tint(movie.base.opacity(0.5)).interactive(), in: TicketPiece(side: .stub))
        .overlay(alignment: .leading) {
            Perforation()
                .stroke(.white.opacity(0.28), style: StrokeStyle(lineWidth: 1.2, dash: [3, 4]))
                .frame(width: 2)
        }
        .contentShape(TicketPiece(side: .stub))
        .onTapGesture(perform: onTear)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isWatched ? "Mark \(movie.title) as not watched" : "Mark \(movie.title) as watched")
    }
}

/// A passport-style rubber stamp.
private struct WatchedStamp: View {
    let color: Color

    var body: some View {
        Text("WATCHED")
            .font(.mono(10, weight: .heavy))
            .tracking(2)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(color, lineWidth: 1.5)
            }
            .rotationEffect(.degrees(-12))
            .opacity(0.9)
    }
}
