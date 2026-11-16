extension Template {
    static let weave = #"""
import SwiftUI

/// A reading of the conversation as a sheet of its own: a woven canvas, always moving, over a few words; each word's
/// row opens its reading, one at a time; under the rows, a legend of the measures the words are read from. It fades in
/// a part at a time; a launch opens it with that done, and with a reading open when it names one.
struct ConverseWeave: View {
    let readings: [ConverseReading]
    /// The legend's lines, in order; with none, no legend.
    let measures: [ConverseMeasure]
    /// A launch opens it with its entrance done.
    var entered = false

    @Environment(\.dismiss) private var dismiss
    @State private var appeared: Bool
    @State private var expanded: String?

    /// `open`: the word whose reading starts open; none when it names no reading of these.
    init(readings: [ConverseReading], measures: [ConverseMeasure] = ConverseReadings.measures, entered: Bool = false, open: String? = nil) {
        self.readings = readings
        self.measures = measures
        self.entered = entered
        _appeared = State(initialValue: entered)
        _expanded = State(initialValue: readings.first { $0.word == open }?.word)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ConverseWeaveCanvas()
                        .padding(.top, {{n:weave.canvasTop}})
                        .padding(.bottom, {{n:weave.canvasBottom}})
                        .padding(.horizontal, {{-n:weave.bleed}})
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: {{n:weave.canvasFade}}), value: appeared)

                    HStack(spacing: 0) {
                        ForEach(Array(readings.enumerated()), id: \.element.id) { index, reading in
                            if index > 0 {
                                Text({{s:weave.separator}})
                                    .font(.custom("Georgia", size: {{n:weave.separatorSize}}))
                                    .foregroundStyle(ConverseWeaveInk.words.opacity({{n:weave.separatorInk}}))
                                    .opacity(appeared ? 1 : 0)
                                    .animation(.easeOut(duration: {{n:weave.separatorFade}}).delay(Double(index) * {{n:weave.wordStagger}} - 0.1), value: appeared)
                                    .padding(.horizontal, {{n:weave.separatorPadding}})
                            }
                            Text(reading.word)
                                .font(.custom("Georgia", size: {{n:weave.words}}))
                                .italic()
                                .foregroundStyle(ConverseWeaveInk.words.opacity({{n:weave.wordsInk}}))
                                .tracking({{n:weave.tracking}})
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : {{n:weave.wordRise}})
                                .animation(.easeOut(duration: {{n:weave.wordFade}}).delay(Double(index) * {{n:weave.wordStagger}}), value: appeared)
                        }
                    }
                    .padding(.top, {{n:weave.wordsTop}})
                    .padding(.bottom, {{n:weave.wordsBottom}})

                    Rectangle()
                        .fill({{c:weave.ruleColor}}.opacity({{n:weave.ruleOpacity}}))
                        .frame(width: {{n:weave.rule#0}}, height: {{n:weave.rule#1}})
                        .padding(.vertical, {{n:weave.rulePadding}})
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: {{n:weave.ruleFade}}), value: appeared)

                    VStack(spacing: 0) {
                        ForEach(Array(readings.enumerated()), id: \.element.id) { index, reading in
                            ConverseReadingRow(reading: reading, isOpen: expanded == reading.word, isLast: index == readings.count - 1) {
                                withAnimation(.easeInOut(duration: {{n:weave.toggle}})) {
                                    expanded = expanded == reading.word ? nil : reading.word
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : {{n:weave.rowRise}})
                            .animation(.easeOut(duration: {{n:weave.rowFade}}).delay({{n:weave.rowStart}} + Double(index) * {{n:weave.wordStagger}}), value: appeared)
                        }
                    }
                    .padding(.horizontal, {{n:weave.inset}})

                    if !measures.isEmpty {
                        legend
                            .padding(.horizontal, {{n:weave.inset}})
                            .padding(.top, {{n:legend.top}})
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: {{n:legend.fade}}), value: appeared)
                    }

                    ConverseBreathingDot(active: true, size: {{n:weave.endDot}})
                        .padding(.top, {{n:weave.endTop}})
                        .padding(.bottom, {{n:weave.endBottom}})
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: {{n:weave.endFade}}), value: appeared)
                }
            }
            .modifier(ConverseInlineTitle())
            .toolbar {
                ConverseBarTitle(text: {{s:weave.title}})
                ToolbarItem(placement: ConversePlatform.trailing) {
                    ConverseCloseButton(tapped: false) { dismiss() }
                }
            }
        }
        .task {
            guard !appeared else { return }
            try? await Task.sleep(for: .seconds({{n:weave.entrance}}))
            appeared = true
        }
    }

    /// The legend: a hairline, then a line a measure, its quality in small tracked capitals in a column of its own,
    /// the indicators it is read from beside it, and its value trailing.
    private var legend: some View {
        VStack(spacing: {{n:legend.spacing}}) {
            Rectangle()
                .fill({{c:weave.divider}}.opacity({{n:weave.dividerOpacity}}))
                .frame(height: {{n:weave.dividerHeight}})
                .padding(.bottom, {{n:legend.ruleBottom}})

            ForEach(measures) { measure in
                HStack(alignment: .top, spacing: 0) {
                    Text(measure.quality)
                        .font(.system(size: {{n:legend.size}}, weight: .medium))
                        .tracking({{n:legend.tracking}})
                        .foregroundStyle({{c:legend.quality}}.opacity({{n:legend.qualityInk}}))
                        .frame(width: {{n:legend.column}}, alignment: .leading)

                    Text(measure.indicator)
                        .font(.system(size: {{n:legend.size}}, design: .monospaced))
                        .foregroundStyle({{c:legend.ink}}.opacity({{n:legend.inkOpacity}}))

                    Spacer()

                    Text(measure.value)
                        .font(.system(size: {{n:legend.size}}, design: .monospaced))
                        .foregroundStyle({{c:legend.ink}}.opacity({{n:legend.inkOpacity}}))
                }
            }
        }
    }
}

/// One word of the weave: a dot and the word; open, its reading below, lined up under the word.
struct ConverseReadingRow: View {
    let reading: ConverseReading
    let isOpen: Bool
    let isLast: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onTap()
            } label: {
                HStack(alignment: .center, spacing: {{n:weave.dotGap}}) {
                    ConverseBreathingDot(active: isOpen, size: {{n:weave.dot}})
                    Text(reading.word)
                        .font(ConverseLook.body)
                        .italic()
                        .foregroundStyle(Color.primary.opacity({{n:ink.body}}))
                        .tracking({{n:weave.wordTracking}})
                    Spacer()
                }
                .padding(.vertical, {{n:weave.rowPadding}})
            }
            .buttonStyle(.plain)

            if isOpen {
                Text(reading.text)
                    .font(.custom("Georgia", size: {{n:weave.reading}}).weight(.light))
                    .italic()
                    .foregroundStyle(ConverseWeaveInk.reading.opacity({{n:weave.readingInk}}))
                    .lineSpacing({{n:weave.readingSpacing}})
                    .padding(.leading, {{n:weave.readingInset}})
                    .padding(.bottom, {{n:weave.readingBottom}})
                    .frame(maxWidth: {{n:weave.readingWidth}}, alignment: .leading)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).animation(.easeOut(duration: {{n:weave.readingIn}})),
                        removal: .opacity.animation(.easeIn(duration: {{n:weave.readingOut}}))
                    ))
            }

            if !isLast {
                Rectangle()
                    .fill({{c:weave.divider}}.opacity({{n:weave.dividerOpacity}}))
                    .frame(height: {{n:weave.dividerHeight}})
            }
        }
    }
}

/// A small dot: faint while its row is closed; open, in the weft's colour, breathing.
struct ConverseBreathingDot: View {
    let active: Bool
    let size: CGFloat
    @State private var breathing = false

    var body: some View {
        Circle()
            .fill(active ? {{c:weave.dotOpen}}.opacity({{n:weave.dotOpenOpacity}}) : {{c:weave.dotClosed}}.opacity({{n:weave.dotClosedOpacity}}))
            .frame(width: size, height: size)
            .opacity(active ? (breathing ? {{n:weave.dotBreaths#1}} : {{n:weave.dotBreaths#0}}) : 1)
            .animation(active ? .easeInOut(duration: {{n:weave.dotBreath}}).repeatForever(autoreverses: true) : .default, value: breathing)
            .onAppear { breathing = true }
    }
}

/// The weave's inks, light and dark.
enum ConverseWeaveInk {
    static var words: Color { ConverseLook.dynamic(light: {{c:weave.inkLight}}, dark: {{c:weave.inkDark}}) }
    static var reading: Color { ConverseLook.dynamic(light: {{c:weave.readingLight}}, dark: {{c:weave.readingDark}}) }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ConverseWeave(readings: ConverseSamples.readings, measures: ConverseSamples.measures, entered: true, open: ConverseSamples.readings.first?.word)
                .presentationDetents([.medium, .large])
        }
}
"""#

    static let weaveCanvas = #"""
import SwiftUI

/// The weave's canvas, redrawn every frame: faint warp lines across, weft lines down fanned about the middle (the
/// middle one strongest), and soft glows breathing where they cross.
struct ConverseWeaveCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / {{n:weave.frames}})) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate * {{n:weave.speed}}
                Self.draw(in: &context, size: size, time: time)
            }
        }
        .frame(height: {{n:weave.height}})
        .accessibilityHidden(true)
    }

    nonisolated static func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let width = Double(size.width)
        let height = Double(size.height)
        let cx = width / 2
        let cy = height / 2

        // The warp: lines across, each waving a little and slowly.
        for index in 0..<{{n:weave.warp}} {
            let line = Double(index)
            let baseY = cy - {{n:weave.warpTop}} + line * {{n:weave.warpSpacing}}
            var path = Path()
            var x = 0.0
            while x < width {
                let y = baseY
                    + sin(x * {{n:weave.warpFrequency}} + t * {{n:weave.warpDrift}} + line * {{n:weave.warpPhase}}) * {{n:weave.warpAmplitude}}
                    + sin(x * {{n:weave.warpSwellFrequency}} + t * {{n:weave.warpSwellDrift}}) * {{n:weave.warpSwell}}
                if x == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                x += {{n:weave.warpStep}}
            }
            let alpha = {{n:weave.warpOpacity}} + sin(t * {{n:weave.warpFlickerRate}} + line * {{n:weave.warpFlickerPhase}}) * {{n:weave.warpFlicker}}
            context.stroke(path, with: .color({{c:weave.warpColor}}.opacity(alpha)), lineWidth: {{n:weave.warpWidth}})
        }

        // The weft: lines down, fanned about the middle, each swinging wider than the one before.
        let middle = Double({{n:weave.weft}} - 1) / 2
        for index in 0..<{{n:weave.weft}} {
            let line = Double(index)
            let isMiddle = line == middle
            let distance = middle > 0 ? abs(line - middle) / middle : 0
            let alpha = isMiddle ? {{n:weave.weftCenter#0}} : {{n:weave.weftOpacity#0}} + (1 - distance) * {{n:weave.weftOpacity#1}}
            var path = Path()
            var y = 0.0
            while y < height {
                let phase = t * {{n:weave.weftDrift}} + line * {{n:weave.weftPhase}}
                let swing = {{n:weave.weftAmplitude}} * ({{n:weave.weftBase}} + line * {{n:weave.weftGrowth}})
                let wave = sin(y * {{n:weave.weftFrequency}} + phase) * swing
                let echo = sin(y * {{n:weave.weftFrequency}} * {{n:weave.weftEchoFrequency}} + phase * {{n:weave.weftEchoDrift}}) * {{n:weave.weftAmplitude}} * {{n:weave.weftEcho}}
                let sway = cos(y * {{n:weave.weftSwayFrequency}} + t * {{n:weave.weftSwayDrift}}) * {{n:weave.weftSway}}
                let x = cx + wave + echo + sway + (line - middle) * {{n:weave.weftSpacing}}
                if y == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                y += {{n:weave.weftStep}}
            }
            context.stroke(path, with: .color({{c:weave.weftColor}}.opacity(alpha)), lineWidth: isMiddle ? {{n:weave.weftCenter#1}} : {{n:weave.weftWidth}})
        }

        // The glows: soft spots swaying about the middle, breathing.
        for index in 0..<{{n:weave.glows}} {
            let spot = Double(index)
            let y = cy - {{n:weave.glowTop}} + spot * {{n:weave.glowSpacing}}
            let x = cx + sin(y * {{n:weave.glowCurve}} + t * {{n:weave.glowFrequency}} + spot * {{n:weave.glowPhase}}) * {{n:weave.glowReach}}
            let breath = sin(t * {{n:weave.glowBreath}} + spot) * 0.5 + 0.5
            let alpha = {{n:weave.glowOpacity#0}} + breath * ({{n:weave.glowOpacity#1}} - {{n:weave.glowOpacity#0}})
            let radius = {{n:weave.glowSize#0}} + breath * ({{n:weave.glowSize#1}} - {{n:weave.glowSize#0}})
            let glow = {{c:weave.glowColor}}
            context.fill(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                with: .radialGradient(Gradient(colors: [glow.opacity(alpha), glow.opacity(0)]),
                                      center: CGPoint(x: x, y: y), startRadius: 0, endRadius: radius)
            )
        }
    }
}

#Preview {
    ConverseWeaveCanvas()
        .padding(.vertical)
}
"""#
}
