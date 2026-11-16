//  WHAT: The measure line: a line of the weave's legend, under its rows. A quality, the indicators it is read from and
//        its value, as the call gives them:
//
//            DIRECTION = lean · momentum, +0.62
//            TEXTURE: "cadence · drift", "0.07"
//
//        `=` or the first colon ends the quality; the value follows the last comma, or the indicators' closing quote,
//        and may be left out. Each piece may be in quotes, and is kept as written: the legend's capitals are the call's.

import Foundation

enum MeasureLine {
    static let form = "a measure is `QUALITY = indicators, value`, like `DIRECTION = lean · momentum, +0.62`"

    static func parse(_ line: String) throws -> (quality: String, indicator: String, value: String) {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let cut = LineSplit.firstTop(text, "=") ?? LineSplit.firstTop(text, ":") else {
            throw ConverseError.line(line, form)
        }
        let quality = unquoted(String(text[..<cut]))
        guard !quality.isEmpty else { throw ConverseError.line(line, "it names no quality before the `=`: \(form)") }
        let rest = text[text.index(after: cut)...].trimmingCharacters(in: .whitespaces)
        var indicator: String
        var value = ""
        if let first = rest.first, first == "\"" || first == "\u{201C}" {
            // The indicators in quotes; the value is what follows the closing quote.
            let closing: Character = first == "\"" ? "\"" : "\u{201D}"
            let opened = rest.index(after: rest.startIndex)
            guard let close = rest[opened...].firstIndex(of: closing) else { throw ConverseError.line(line, "its quote is never closed") }
            indicator = String(rest[opened..<close])
            var after = rest[rest.index(after: close)...]
            while let next = after.first, next == " " || next == "," { after.removeFirst() }
            value = unquoted(String(after))
        } else if let comma = LineSplit.lastTop(rest, ",") {
            indicator = unquoted(String(rest[..<comma]))
            value = unquoted(String(rest[rest.index(after: comma)...]))
        } else {
            indicator = unquoted(rest)
        }
        indicator = indicator.trimmingCharacters(in: .whitespaces)
        guard !indicator.isEmpty else { throw ConverseError.line(line, "`\(quality)` names no indicators after the `=`: \(form)") }
        return (quality, indicator, value)
    }

    /// `text` trimmed, its quotes taken off when it is one quoted piece.
    private static func unquoted(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if case .success(let word) = WordLines.word(trimmed) { return word }
        return trimmed
    }
}
