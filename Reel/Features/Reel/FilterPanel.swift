import SwiftUI

/// Mood, era and length controls. Changes apply live — the count updates as you scrub.
struct FilterPanel: View {
    @Bindable var store: MovieStore
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tune the reel")
                        .font(.display(26))
                        .foregroundStyle(Theme.primaryText)
                    Text("\(store.deck.count) FILMS ON THE REEL")
                        .font(.mono(11, weight: .semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: store.deck.count)
                }
                Spacer()
                if !store.filters.isDefault {
                    Button("Reset") {
                        withAnimation(.snappy) { store.filters = Filters() }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ember)
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                    .transition(.blurReplace)
                }
            }

            MoodDial(selection: $store.filters.mood)

            EraRuler(range: $store.filters.era)

            LengthPicker(selection: $store.filters.length)

            Button(action: onDone) {
                Text(store.deck.isEmpty ? "Nothing matches — loosen up" : "Roll with \(store.deck.count) films")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentTransition(.numericText())
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.ember)
            .disabled(store.deck.isEmpty)
        }
        .padding(20)
        .animation(.snappy, value: store.filters.isDefault)
    }
}

// MARK: - Mood dial

/// A horizontal dial of mood glyphs. The one under the centre is the selection,
/// and glyphs shrink and fade with distance from it.
struct MoodDial: View {
    @Binding var selection: Mood?
    @State private var scrolledID: String?

    private static let allID = "all"
    private let options: [String] = [MoodDial.allID] + Mood.allCases.map(\.rawValue)
    private let itemSize: CGFloat = 54

    private var focusedMood: Mood? { scrolledID.flatMap(Mood.init(rawValue:)) }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let focusX = proxy.frame(in: .global).midX
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(options, id: \.self) { id in
                            glyph(for: Mood(rawValue: id))
                                .frame(width: itemSize, height: itemSize)
                                .visualEffect { content, geometry in
                                    let midX = geometry.frame(in: .global).midX
                                    let distance = abs(midX - focusX) / 110
                                    return content
                                        .scaleEffect(max(0.6, 1 - distance * 0.4))
                                        .opacity(max(0.28, 1 - distance * 0.6))
                                }
                                .onTapGesture {
                                    withAnimation(.snappy) { scrolledID = id }
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID, anchor: .center)
                .contentMargins(.horizontal, max(0, (width - itemSize) / 2), for: .scrollContent)
            }
            .frame(height: itemSize + 6)

            Text(focusedMood?.title.uppercased() ?? "ANY MOOD")
                .font(.mono(11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(focusedMood?.tint ?? Theme.primaryText)
                .contentTransition(.interpolate)
                .animation(.snappy, value: scrolledID)
        }
        .onAppear { scrolledID = selection?.rawValue ?? Self.allID }
        .onChange(of: scrolledID) { _, id in
            let mood = id.flatMap(Mood.init(rawValue:))
            if mood != selection { selection = mood }
        }
        .sensoryFeedback(.selection, trigger: scrolledID)
    }

    private func glyph(for mood: Mood?) -> some View {
        let tint = mood?.tint ?? .white
        return ZStack {
            Circle().fill(tint.opacity(0.16))
            Circle().strokeBorder(tint.opacity(0.35), lineWidth: 1)
            Image(systemName: mood?.symbol ?? "sparkles")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Era ruler

/// A tick-mark timeline from 1950 to today with two draggable handles.
struct EraRuler: View {
    @Binding var range: ClosedRange<Int>
    @State private var activeHandle: Handle?

    private enum Handle { case lower, upper }
    private let bounds = Filters.eraBounds

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("ERA")
                    .font(.mono(11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.tertiaryText)
                Spacer()
                Text(verbatim: "\(range.lowerBound) — \(range.upperBound)")
                    .font(.mono(13, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: range)
            }

            HStack(spacing: 4) {
                shiftButton("chevron.left", by: -10)
                GeometryReader { proxy in
                    track(width: proxy.size.width)
                }
                .frame(height: 46)
                shiftButton("chevron.right", by: 10)
            }

            GeometryReader { proxy in
                ForEach([1950, 1970, 1990, 2010], id: \.self) { year in
                    Text(verbatim: "’\(year % 100 == 0 ? "00" : String(year % 100))")
                        .font(.mono(10, weight: .medium))
                        .foregroundStyle(Theme.tertiaryText)
                        .position(x: x(for: year, width: proxy.size.width), y: 6)
                }
            }
            .frame(height: 12)
            .padding(.horizontal, 30)
        }
        .sensoryFeedback(.selection, trigger: range)
    }

    private func track(width: CGFloat) -> some View {
        let lowerX = x(for: range.lowerBound, width: width)
        let upperX = x(for: range.upperBound, width: width)
        let first = bounds.lowerBound
        let last = bounds.upperBound
        let lower = range.lowerBound
        let upper = range.upperBound

        return ZStack(alignment: .leading) {
            Rectangle()
                .fill(Theme.ember.opacity(0.16))
                .frame(width: max(2, upperX - lowerX), height: 30)
                .offset(x: lowerX)

            Canvas { context, size in
                let span = CGFloat(last - first)
                for year in first...last {
                    let x = size.width * CGFloat(year - first) / span
                    let major = year % 10 == 0
                    let height: CGFloat = major ? 26 : (year % 5 == 0 ? 16 : 9)
                    let inside = year >= lower && year <= upper
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: (size.height - height) / 2))
                    tick.addLine(to: CGPoint(x: x, y: (size.height + height) / 2))
                    let alpha = inside ? (major ? 0.95 : 0.55) : (major ? 0.32 : 0.14)
                    context.stroke(tick, with: .color(.white.opacity(alpha)), lineWidth: major ? 1.5 : 1)
                }
            }

            handle(active: activeHandle == .lower).offset(x: lowerX - 2)
            handle(active: activeHandle == .upper).offset(x: upperX - 2)
        }
        .frame(width: width, height: 46)
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if activeHandle == nil {
                        let toLower = abs(value.startLocation.x - lowerX)
                        let toUpper = abs(value.startLocation.x - upperX)
                        if toLower == toUpper {
                            activeHandle = value.location.x < value.startLocation.x ? .lower : .upper
                        } else {
                            activeHandle = toLower < toUpper ? .lower : .upper
                        }
                    }
                    let year = self.year(at: value.location.x, width: width)
                    switch activeHandle {
                    case .lower: range = min(year, range.upperBound - 1)...range.upperBound
                    case .upper: range = range.lowerBound...max(year, range.lowerBound + 1)
                    case nil: break
                    }
                }
                .onEnded { _ in
                    withAnimation(.snappy) { activeHandle = nil }
                }
        )
        .animation(.snappy(duration: 0.2), value: activeHandle)
    }

    private func handle(active: Bool) -> some View {
        Capsule()
            .fill(Theme.ember)
            .frame(width: 4, height: active ? 42 : 32)
            .shadow(color: Theme.ember.opacity(0.7), radius: active ? 8 : 4)
    }

    private func shiftButton(_ symbol: String, by delta: Int) -> some View {
        Button {
            withAnimation(.snappy) { shift(by: delta) }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 26, height: 46)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func shift(by delta: Int) {
        let width = range.upperBound - range.lowerBound
        var lower = range.lowerBound + delta
        lower = min(max(lower, bounds.lowerBound), bounds.upperBound - width)
        range = lower...(lower + width)
    }

    private func x(for year: Int, width: CGFloat) -> CGFloat {
        width * CGFloat(year - bounds.lowerBound) / CGFloat(bounds.upperBound - bounds.lowerBound)
    }

    private func year(at x: CGFloat, width: CGFloat) -> Int {
        let fraction = min(max(x / max(width, 1), 0), 1)
        return bounds.lowerBound + Int((fraction * CGFloat(bounds.upperBound - bounds.lowerBound)).rounded())
    }
}

// MARK: - Length

struct LengthPicker: View {
    @Binding var selection: Filters.Length
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Filters.Length.allCases) { option in
                let selected = option == selection
                Text(option.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selected ? Color.black : Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selected {
                            Capsule()
                                .fill(.white)
                                .matchedGeometryEffect(id: "length", in: pill)
                        }
                    }
                    .contentShape(.capsule)
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.32)) { selection = option }
                    }
            }
        }
        .padding(4)
        .background(.white.opacity(0.07), in: .capsule)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
