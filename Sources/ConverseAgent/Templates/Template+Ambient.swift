extension Template {
    static let orb = #"""
import SwiftUI

/// The slow haze behind the stage: a radial gradient that drifts and breathes, its centre a little above the middle
/// of the screen, scaling about the screen's centre. It ignores the safe areas, and takes no touches.
struct ConverseOrb: View {
    @State private var drifting = false

    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            {{c:orb.inner}}.opacity({{n:orb.opacity}}),
                            {{c:orb.outer}}.opacity({{n:orb.outerOpacity}}),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: {{n:orb.radius}}
                    )
                )
                .frame(width: {{n:orb.size}}, height: {{n:orb.size}})
                .position(
                    x: geometry.size.width / 2 + (drifting ? {{-n:orb.offset}} : {{n:orb.offset}}),
                    y: geometry.size.height * {{n:orb.center}} + (drifting ? {{n:orb.offset}} : {{-n:orb.offset}})
                )
                .scaleEffect(drifting ? {{n:orb.scales#1}} : {{n:orb.scales#0}})
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: {{n:orb.drift}}).repeatForever(autoreverses: true)) {
                drifting = true
            }
        }
    }
}

#Preview {
    ConverseOrb()
}
"""#

    static let dots = #"""
import SwiftUI

/// The dot of an empty stage: small and faint, breathing slowly.
struct ConverseIdleDot: View {
    @State private var breathing = false

    var body: some View {
        Circle()
            .fill(Color.primary.opacity(breathing ? {{n:idle.glow}} : {{n:idle.opacity}}))
            .frame(width: breathing ? {{n:idle.grow}} : {{n:idle.size}}, height: breathing ? {{n:idle.grow}} : {{n:idle.size}})
            .animation(.easeInOut(duration: {{n:idle.breath}}).repeatForever(autoreverses: true), value: breathing)
            .accessibilityHidden(true)
            .onAppear { breathing = true }
    }
}

/// Three dots in a reply's place while it is thought of, each brightening in turn.
struct ConverseThinkingDots: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: {{n:dots.spacing}}) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.primary.opacity(pulsing ? {{n:dots.high}} : {{n:dots.low}}))
                    .frame(width: {{n:dots.size}}, height: {{n:dots.size}})
                    .animation(
                        .easeInOut(duration: {{n:dots.duration}}).repeatForever(autoreverses: true).delay(Double(index) * {{n:dots.delay}}),
                        value: pulsing
                    )
            }
        }
        .frame(height: {{n:dots.height}}, alignment: .leading)
        .accessibilityHidden(true)
        .onAppear { pulsing = true }
    }
}

/// Three still dots in a transcript's reply while it is thought of.
struct ConverseStillDots: View {
    var body: some View {
        HStack(spacing: {{n:echoes.dotSpacing}}) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.secondary.opacity({{n:echoes.dotOpacity}}))
                    .frame(width: {{n:echoes.dot}}, height: {{n:echoes.dot}})
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 40) {
        ConverseIdleDot()
        ConverseThinkingDots()
        ConverseStillDots()
    }
}
"""#

    static let glassEdge = #"""
import SwiftUI

/// A band of frosted glass along the top or the bottom of the screen, thickest at the edge and fading inward, so
/// content slides under the bars softly. It takes no touches.
struct ConverseGlassEdge: View {
    let edge: VerticalEdge

    var body: some View {
        let outward: UnitPoint = edge == .top ? .top : .bottom
        let inward: UnitPoint = edge == .top ? .bottom : .top
        ZStack {
            Rectangle().fill(.regularMaterial)
            LinearGradient(colors: [Color.white.opacity({{n:edge.tint}}), .clear], startPoint: outward, endPoint: inward)
        }
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(0.92), location: 0.2),
                    .init(color: .black.opacity(0.7), location: 0.45),
                    .init(color: .black.opacity(0.3), location: 0.72),
                    .init(color: .black.opacity(0.05), location: 0.92),
                    .init(color: .clear, location: 1),
                ],
                startPoint: outward,
                endPoint: inward
            )
        }
        .frame(height: {{n:edge.height}})
        .frame(maxHeight: .infinity, alignment: edge == .top ? .top : .bottom)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.orange
        ConverseGlassEdge(edge: .top)
        ConverseGlassEdge(edge: .bottom)
    }
}
"""#
}
