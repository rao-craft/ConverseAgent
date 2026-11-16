//  WHAT: The launch line: a destination, and the state the views open in for it.
//
//            void.reply = reply(0)
//            echoes = transcript(0, 1, 2)
//            contribution = source(0, "Orbital Mechanics")
//
//        States: empty; reply(i); transcript(i, …); sources(i); source(i, "group"); weave(i, …). An index is an
//        exchange's place in the app's list, from 0; the brackets may be left out (`source 0 "Orbital Mechanics"`),
//        and a missing index is 0.

import Foundation

struct LaunchState: Sendable, Equatable {
    enum Name: String, CaseIterable, Sendable { case empty, reply, transcript, sources, source, weave }

    let name: Name
    let indices: [Int]
    let group: String?

    /// As Swift: `.source(0, "Orbital Mechanics")`.
    var swift: String {
        switch name {
        case .empty: return ".empty"
        case .reply, .sources: return ".\(name.rawValue)(\(indices[0]))"
        case .transcript, .weave: return ".\(name.rawValue)([\(indices.map(String.init).joined(separator: ", "))])"
        case .source: return ".source(\(indices[0]), \(SwiftLiteral.string(group ?? "")))"
        }
    }

    /// As a line writes it: `source(0, "Orbital Mechanics")`.
    var line: String {
        switch name {
        case .empty: return "empty"
        case .reply, .sources: return "\(name.rawValue)(\(indices[0]))"
        case .transcript, .weave: return "\(name.rawValue)(\(indices.map(String.init).joined(separator: ", ")))"
        case .source: return "source(\(indices[0]), \(SwiftLiteral.string(group ?? "")))"
        }
    }
}

enum LaunchLine {
    static let forms = "empty, reply(i), transcript(i, …), sources(i), source(i, \"group\") or weave(i, …)"

    static func parse(_ line: String) throws -> (destination: String, state: LaunchState) {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let equals = LineSplit.firstTop(text, "=") ?? LineSplit.firstTop(text, ":") else {
            throw ConverseError.line(line, "a launch line is `destination = state`, like `void.reply = reply(0)`")
        }
        var destination = text[..<equals].trimmingCharacters(in: .whitespaces)
        if destination.hasPrefix("\""), destination.hasSuffix("\""), destination.count > 1 { destination = String(destination.dropFirst().dropLast()) }
        guard destination.range(of: #"^[A-Za-z0-9_][A-Za-z0-9_.\-]*$"#, options: .regularExpression) != nil else {
            throw ConverseError.line(line, "`\(destination)` is not a destination name (letters, digits, dots, like `void.reply`)")
        }
        let rest = text[text.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        let word = String(rest.prefix { $0.isLetter })
        guard let name = LaunchState.Name(rawValue: word.lowercased()) else {
            throw ConverseError.line(line, "`\(word.isEmpty ? rest : word)` is not a state: a destination opens " + forms)
        }
        var arguments = rest.dropFirst(word.count).trimmingCharacters(in: .whitespaces)
        if arguments.hasPrefix("(") {
            arguments = String(arguments.dropFirst())
            if arguments.hasSuffix(")") { arguments = String(arguments.dropLast()) }
        }
        var indices: [Int] = []
        var group: String?
        var cursor = Substring(arguments)
        while true {
            while let first = cursor.first, first == " " || first == "," { cursor.removeFirst() }
            guard let first = cursor.first else { break }
            if first == "\"" || first == "\u{201C}" {
                let closing: Character = first == "\"" ? "\"" : "\u{201D}"
                guard let close = cursor.dropFirst().firstIndex(of: closing) else { throw ConverseError.line(line, "its group's quote is never closed") }
                guard group == nil else { throw ConverseError.line(line, "it names two groups") }
                group = String(cursor[cursor.index(after: cursor.startIndex)..<close])
                cursor = cursor[cursor.index(after: close)...]
            } else {
                let token = cursor.prefix { $0 != " " && $0 != "," }
                cursor = cursor.dropFirst(token.count)
                guard let index = Int(token), index >= 0 else {
                    throw ConverseError.line(line, "`\(token)` is not an exchange's index (0 is the first) or a group in quotes")
                }
                indices.append(index)
            }
        }
        switch name {
        case .empty:
            guard indices.isEmpty, group == nil else { throw ConverseError.line(line, "empty opens with no exchange, so it takes nothing") }
        case .reply, .sources:
            guard group == nil else { throw ConverseError.line(line, "\(name.rawValue) takes one index and no group") }
            guard indices.count <= 1 else { throw ConverseError.line(line, "\(name.rawValue) opens one exchange: `\(name.rawValue)(0)`") }
            if indices.isEmpty { indices = [0] }
        case .transcript, .weave:
            guard group == nil else { throw ConverseError.line(line, "\(name.rawValue) takes indices and no group") }
            guard !indices.isEmpty else { throw ConverseError.line(line, "\(name.rawValue) names the exchanges it holds: `\(name.rawValue)(0, 1, 2)`") }
        case .source:
            guard let named = group, !named.isEmpty else {
                throw ConverseError.line(line, "source names the group it opens, in quotes: `source(0, \"Orbital Mechanics\")`")
            }
            guard indices.count <= 1 else { throw ConverseError.line(line, "source opens one exchange's group: `source(0, \"\(named)\")`") }
            if indices.isEmpty { indices = [0] }
        }
        return (destination, LaunchState(name: name, indices: indices, group: group))
    }
}

/// The reading line: `word: the reading it opens`, the word before the first colon.
enum ReadingLine {
    static func parse(_ line: String) throws -> (word: String, text: String) {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let colon = text.firstIndex(of: ":") else {
            throw ConverseError.line(line, "a reading is `word: the reading`, like `outward: The weft is running ahead of the warp.`")
        }
        var word = text[..<colon].trimmingCharacters(in: .whitespaces)
        if case .success(let unquoted) = WordLines.word(word) { word = unquoted }
        var reading = String(text[text.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        if reading.hasPrefix("\""), case .success(let unquoted) = WordLines.word(reading) { reading = unquoted }
        guard !word.isEmpty else { throw ConverseError.line(line, "it names no word before the colon") }
        guard !reading.isEmpty else { throw ConverseError.line(line, "`\(word)` has no reading after the colon") }
        return (word, reading)
    }
}
