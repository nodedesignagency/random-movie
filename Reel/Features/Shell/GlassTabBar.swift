import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case reel, orbit, stubs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reel: "Reel"
        case .orbit: "Orbit"
        case .stubs: "Stubs"
        }
    }

    var symbol: String {
        switch self {
        case .reel: "rectangle.stack.fill"
        case .orbit: "point.3.filled.connected.trianglepath.dotted"
        case .stubs: "ticket.fill"
        }
    }
}

/// Floating liquid-glass bar: a capsule of tabs where the selected tab grows to
/// show its name, plus the dice — the app's one big button.
struct GlassTabBar: View {
    @Binding var selection: AppTab
    var spins: Int
    var onSpin: () -> Void

    @Namespace private var pill
    @State private var diceTurns = 0.0

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                HStack(spacing: 2) {
                    ForEach(AppTab.allCases) { tab in
                        tabButton(tab)
                    }
                }
                .padding(5)
                .glassEffect(.regular, in: .capsule)

                Button(action: onSpin) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(diceTurns * 360))
                        .frame(width: 62, height: 62)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(Theme.ember.opacity(0.6)).interactive(), in: .circle)
                .accessibilityLabel("Spin the reel")
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .onChange(of: spins) {
            withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: 2.0)) { diceTurns += 2 }
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let selected = tab == selection
        return Button {
            withAnimation(.snappy(duration: 0.34)) { selection = tab }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 16, weight: .semibold))
                if selected {
                    Text(tab.title)
                        .font(.system(size: 14, weight: .semibold))
                        .fixedSize()
                        .transition(.blurReplace)
                }
            }
            .foregroundStyle(selected ? Theme.primaryText : Theme.secondaryText)
            .padding(.horizontal, selected ? 18 : 15)
            .frame(height: 52)
            .background {
                if selected {
                    Capsule()
                        .fill(.white.opacity(0.14))
                        .matchedGeometryEffect(id: "tab", in: pill)
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}
