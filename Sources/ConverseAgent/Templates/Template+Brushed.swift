extension Template {
    static let brushedReply = #"""
import SwiftUI

/// A settled reply with its phrases brushed: laid out word by word so each word's frame is known, then one stroke a
/// phrase a line, in its owner's colour, over the words, each fading in a little after the one before. A tap on a
/// stroke tells whose it is; a tap anywhere else on the reply is the reply's.
struct ConverseBrushedReply: View {
    let exchange: ConverseExchange
    var onReply: () -> Void = {}
    var onStroke: ((ConverseOwner) -> Void)? = nil

    var body: some View {
        let paragraphs = ConverseMarkup.paragraphs(exchange.reply ?? "")
        VStack(alignment: .leading, spacing: {{n:column.paragraphs}}) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, runs in
                ConverseBrushedParagraph(words: ConverseBrushedParagraph.words(runs, in: exchange), paragraph: index, onStroke: onStroke)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onReply)
    }
}

/// One paragraph of a brushed reply: its words in a wrapping row, its strokes over them.
struct ConverseBrushedParagraph: View {
    /// A word with the spaces after it, and the phrase it belongs to, if any.
    struct Word: Identifiable {
        let id: Int
        let text: String
        let trailing: String
        let bold: Bool
        let code: Bool
        /// The phrase's place among the paragraph's phrases; nil for a word no phrase touches.
        let span: Int?
        let owner: ConverseOwner?
        let tone: Int
    }

    let words: [Word]
    let paragraph: Int
    let onStroke: ((ConverseOwner) -> Void)?

    var body: some View {
        ConverseFlowLayout(rowSpacing: {{n:stroke.rows}}) {
            ForEach(words) { word in
                styled(word)
                    .anchorPreference(key: ConverseWordFrames.self, value: .bounds) { anchor in
                        word.span == nil ? [:] : [word.id: anchor]
                    }
            }
        }
        .overlayPreferenceValue(ConverseWordFrames.self) { anchors in
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    ForEach(Array(marks(anchors, proxy).enumerated()), id: \.element.id) { index, mark in
                        ConverseStrokeMarkView(mark: mark, index: index, onStroke: onStroke)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    /// A word and its trailing space as one run of text, so a stroke covers the space after each word it brushes.
    private func styled(_ word: Word) -> Text {
        let text = Text(verbatim: word.text + word.trailing)
        if word.code {
            return text
                .font(.system(size: {{n:column.code}}, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.primary.opacity({{n:ink.note}}))
        }
        return text
            .font(word.bold ? ConverseLook.note.weight(.semibold) : ConverseLook.note)
            .italic()
            .kerning({{n:column.replyKerning}})
            .foregroundStyle(Color.primary.opacity({{n:ink.note}}))
    }

    /// Whether one word's frame comes before another's as the reply is read: line by line (tops within 4 points
    /// share a line), then leading to trailing.
    private static func inReadingOrder(_ first: CGRect, _ second: CGRect) -> Bool {
        let sameLine = abs(first.minY - second.minY) < 4
        return sameLine ? first.minX < second.minX : first.minY < second.minY
    }

    /// The strokes: each phrase's word frames merged line by line (frames whose tops lie within 4 points share a
    /// line), one stroke a line, phrase after phrase and each phrase's lines top to bottom.
    private func marks(_ anchors: [Int: Anchor<CGRect>], _ proxy: GeometryProxy) -> [ConverseStrokeMark] {
        var marks: [ConverseStrokeMark] = []
        var spans: [Int] = []
        for word in words { if let span = word.span, !spans.contains(span) { spans.append(span) } }
        for span in spans {
            let brushed = words.filter { $0.span == span }
            let frames: [CGRect] = brushed.compactMap { word -> CGRect? in
                guard let anchor = anchors[word.id] else { return nil }
                return proxy[anchor]
            }
            .sorted(by: Self.inReadingOrder)
            var lines: [CGRect] = []
            var top: CGFloat = 0
            for frame in frames {
                if let last = lines.last, abs(frame.minY - top) < 4 {
                    lines[lines.count - 1] = last.union(frame)
                } else {
                    lines.append(frame)
                    top = frame.minY
                }
            }
            let first = brushed.first
            for (line, frame) in lines.enumerated() {
                marks.append(ConverseStrokeMark(span: span, line: line, paragraph: paragraph, frame: frame,
                                                tone: first?.tone ?? 0, owner: first?.owner))
            }
        }
        return marks
    }

    /// A paragraph's words, each phrase widened to the whole words it touches, punctuation and all.
    static func words(_ runs: [ConverseRun], in exchange: ConverseExchange) -> [Word] {
        var pieces: [(text: String, trailing: String, bold: Bool, code: Bool, start: Int)] = []
        var text = "", trailing = "", bold = false, code = false, start = 0, offset = 0
        func flush() {
            if !text.isEmpty { pieces.append((text, trailing, bold, code, start)) }
            text = ""
            trailing = ""
        }
        for run in runs {
            for character in run.text {
                if character == " " {
                    if !text.isEmpty { trailing.append(character) }
                } else {
                    if !trailing.isEmpty { flush() }
                    if text.isEmpty {
                        start = offset
                        bold = run.bold
                        code = run.code
                    }
                    text.append(character)
                }
                offset += 1
            }
        }
        flush()

        // Each phrase found in the paragraph's text, in order: its span, owner and colour.
        let plain = runs.map(\.text).joined()
        var spans: [(range: Range<Int>, owner: ConverseOwner?, tone: Int)] = []
        var strangers: [String] = []
        for highlight in exchange.highlights where !highlight.phrase.isEmpty {
            guard let found = plain.range(of: highlight.phrase) ?? plain.range(of: highlight.phrase, options: .caseInsensitive) else { continue }
            let lower = plain.distance(from: plain.startIndex, to: found.lowerBound)
            let upper = plain.distance(from: plain.startIndex, to: found.upperBound)
            let owner = exchange.owner(of: highlight)
            var tone: Int
            if let owner {
                tone = exchange.tone(of: owner)
            } else {
                if !strangers.contains(highlight.owner) { strangers.append(highlight.owner) }
                tone = exchange.owners.count + (strangers.firstIndex(of: highlight.owner) ?? 0)
            }
            spans.append((lower..<upper, owner, tone))
        }
        return pieces.enumerated().map { index, piece in
            let range = piece.start..<(piece.start + piece.text.count)
            let span = spans.firstIndex { $0.range.overlaps(range) }
            return Word(id: index, text: piece.text, trailing: piece.trailing, bold: piece.bold, code: piece.code, span: span,
                        owner: span.flatMap { spans[$0].owner }, tone: span.map { spans[$0].tone } ?? 0)
        }
    }
}

/// One stroke to draw: a phrase's words on one line, merged.
struct ConverseStrokeMark: Identifiable {
    let span: Int
    let line: Int
    let paragraph: Int
    var frame: CGRect
    let tone: Int
    let owner: ConverseOwner?

    var id: String { "\(paragraph)-\(span)-\(line)" }
    /// Fixed per phrase and line, so the stroke keeps its shape across redraws and differs from its neighbours.
    var seed: Int { paragraph * 1_000 + span * 10 + line }
}

/// A stroke drawn over its words, a little wider and taller than they are, fading in after the strokes before it.
struct ConverseStrokeMarkView: View {
    let mark: ConverseStrokeMark
    let index: Int
    let onStroke: ((ConverseOwner) -> Void)?
    @State private var opacity = 0.0

    var body: some View {
        ConverseStroke(seed: mark.seed)
            .fill(ConverseLook.tone(mark.tone).opacity({{n:stroke.opacity}}))
            .frame(width: mark.frame.width + {{n:stroke.width}}, height: mark.frame.height + {{n:stroke.height}})
            .position(x: mark.frame.midX, y: mark.frame.midY)
            .opacity(opacity)
            .animation(.easeIn(duration: {{n:stroke.fade}}).delay(Double(index) * {{n:stroke.stagger}}), value: opacity)
            .onTapGesture {
                if let owner = mark.owner { onStroke?(owner) }
            }
            .allowsHitTesting(onStroke != nil && mark.owner != nil)
            .onAppear { opacity = 1 }
    }
}

/// Where each brushed word was laid out.
struct ConverseWordFrames: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

#Preview {
    ConverseBrushedReply(exchange: ConverseSamples.exchanges[0])
        .frame(maxWidth: {{n:column.width}})
        .padding()
}
"""#
}
