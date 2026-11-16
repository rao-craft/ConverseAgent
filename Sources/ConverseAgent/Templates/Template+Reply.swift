extension Template {
    static let replyText = #"""
import SwiftUI

/// A stretch of a reply in one style: plain, bold or code. A reply's inline markdown is read into these.
struct ConverseRun: Hashable, Sendable {
    var text: String
    var bold = false
    var code = false
}

/// A reply's inline markdown, read: paragraphs split at blank lines, `**bold**` and `` `code` `` marked, the marks
/// themselves dropped. Nothing else is read, so a reply never draws as a list or a heading.
enum ConverseMarkup {
    /// Each paragraph's runs.
    static func paragraphs(_ text: String) -> [[ConverseRun]] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .newlines) }
            .filter { !$0.isEmpty }
            .map(runs)
    }

    /// One paragraph's runs.
    static func runs(_ paragraph: String) -> [ConverseRun] {
        var runs: [ConverseRun] = []
        var current = ConverseRun(text: "")
        let characters = Array(paragraph.replacingOccurrences(of: "\n", with: " "))
        var index = 0
        func close() {
            if !current.text.isEmpty { runs.append(current) }
            current = ConverseRun(text: "", bold: current.bold, code: current.code)
        }
        while index < characters.count {
            let character = characters[index]
            if !current.code, character == "*", index + 1 < characters.count, characters[index + 1] == "*" {
                close()
                current.bold.toggle()
                index += 2
                continue
            }
            if character == "`" {
                close()
                current.code.toggle()
                index += 1
                continue
            }
            current.text.append(character)
            index += 1
        }
        close()
        return runs
    }

    /// How many characters the runs show.
    static func count(_ paragraphs: [[ConverseRun]]) -> Int {
        paragraphs.reduce(0) { total, runs in total + runs.reduce(0) { $0 + $1.text.count } }
    }

    /// The first `count` characters of the paragraphs, as runs; a paragraph not reached yet is left out.
    static func prefix(_ paragraphs: [[ConverseRun]], _ count: Int) -> [[ConverseRun]] {
        var left = count
        var shown: [[ConverseRun]] = []
        for runs in paragraphs {
            guard left > 0 else { break }
            var kept: [ConverseRun] = []
            for run in runs where left > 0 {
                var part = run
                part.text = String(run.text.prefix(left))
                left -= part.text.count
                kept.append(part)
            }
            shown.append(kept)
        }
        return shown
    }
}

/// A reply as text: its paragraphs apart, bold semibold and code upright in a fixed width, and while it is typed out,
/// a cursor after the last character, set in the surrounding font as the reply's run leaves it.
struct ConverseReplyText: View {
    let paragraphs: [[ConverseRun]]
    let font: Font
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat
    let kerning: CGFloat
    let opacity: Double
    /// The cursor: shown, hidden with its place kept, or nil for none.
    let cursor: Bool?

    init(text: String, font: Font = ConverseLook.note, lineSpacing: CGFloat = {{n:column.replySpacing}},
         paragraphSpacing: CGFloat = {{n:column.paragraphs}}, kerning: CGFloat = {{n:column.replyKerning}},
         opacity: Double = {{n:ink.note}}) {
        self.init(paragraphs: ConverseMarkup.paragraphs(text), font: font, lineSpacing: lineSpacing,
                  paragraphSpacing: paragraphSpacing, kerning: kerning, opacity: opacity)
    }

    init(paragraphs: [[ConverseRun]], font: Font = ConverseLook.note, lineSpacing: CGFloat = {{n:column.replySpacing}},
         paragraphSpacing: CGFloat = {{n:column.paragraphs}}, kerning: CGFloat = {{n:column.replyKerning}},
         opacity: Double = {{n:ink.note}}, cursor: Bool? = nil) {
        self.paragraphs = paragraphs
        self.font = font
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.kerning = kerning
        self.opacity = opacity
        self.cursor = cursor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: paragraphSpacing) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, runs in
                paragraph(runs, last: index == paragraphs.count - 1)
                    .lineSpacing(lineSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if paragraphs.isEmpty, cursor != nil {
                paragraph([], last: true)
            }
        }
    }

    private func paragraph(_ runs: [ConverseRun], last: Bool) -> Text {
        var text = runs.reduce(Text(verbatim: "")) { partial, run in Text("\(partial)\(styled(run))") }
        if last, let cursor {
            // Swapped with two clear spaces, so the line keeps its length as the cursor blinks.
            let mark = Text(verbatim: cursor ? {{s:stage.cursor}} : "  ")
                .italic()
                .kerning(kerning)
                .foregroundStyle(Color.primary.opacity(cursor ? {{n:reveal.cursorOpacity}} : 0))
            text = Text("\(text)\(mark)")
        }
        return text
    }

    private func styled(_ run: ConverseRun) -> Text {
        if run.code {
            return Text(verbatim: run.text)
                .font(.system(size: {{n:column.code}}, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.primary.opacity(opacity))
        }
        return Text(verbatim: run.text)
            .font(run.bold ? font.italic().weight(.semibold) : font.italic())
            .kerning(kerning)
            .foregroundStyle(Color.primary.opacity(opacity))
    }
}

#Preview {
    ConverseReplyText(paragraphs: ConverseMarkup.paragraphs(ConverseSamples.exchanges[0].reply ?? ""), cursor: true)
        .padding()
}
"""#
}
