//  WHAT: The launch line: a destination, and the state the views open in for it.
//
//            void.reply = reply(0)
//            echoes = transcript(0)
//            echoes.full = transcript(0) large
//            contribution = source(0, "Orbital Mechanics")
//
//        States: empty; reply(i); transcript(i, …); sources(i); source(i, "group"); weave(i, …), with a reading's
//        word in quotes to open it (`weave(0, "outward")`). An index is an exchange's place in the app's list, from 0;
//        the brackets may be left out (`source 0 "Orbital Mechanics"`), and a missing index is 0. A height after a
//        state that opens a sheet, `medium` or `large`, opens its sheets at that detent; medium when left out.

import Foundation

struct LaunchState: Sendable, Equatable {
    enum Name: String, CaseIterable, Sendable { case empty, reply, transcript, sources, source, weave }
    enum Height: String, CaseIterable, Sendable { case medium, large }

    let name: Name
    let indices: [Int]
    /// The group `source` pushes, or the reading `weave` opens, by the name in quotes.
    let quoted: String?
    /// The detent its sheets open at, when the line gave one.
    let height: Height?

    init(name: Name, indices: [Int], quoted: String? = nil, height: Height? = nil) {
        self.name = name
        self.indices = indices
        self.quoted = quoted
        self.height = height
    }

    /// Whether its sheets open at the large detent.
    var large: Bool { height == .large }

    /// The state as Swift: `.source(0, "Orbital Mechanics")`, `.weave([0], nil)`.
    var swiftState: String {
        let list = "[" + indices.map(String.init).joined(separator: ", ") + "]"
        switch name {
        case .empty: return ".empty"
        case .reply, .sources: return ".\(name.rawValue)(\(indices[0]))"
        case .transcript: return ".transcript(\(list))"
        case .source: return ".source(\(indices[0]), \(SwiftLiteral.string(quoted ?? "")))"
        case .weave: return ".weave(\(list), \(quoted.map(SwiftLiteral.string) ?? "nil"))"
        }
    }

    /// The launch as Swift: `<Prefix>Launch(.transcript([0]), large: true)`.
    func swift(prefix: String) -> String {
        "\(prefix)Launch(\(swiftState)\(large ? ", large: true" : ""))"
    }

    /// As a line writes it: `source(0, "Orbital Mechanics")`, `transcript(0) large`.
    var line: String {
        var arguments = indices.map(String.init)
        if let quoted { arguments.append(SwiftLiteral.string(quoted)) }
        let state = name == .empty ? "empty" : "\(name.rawValue)(\(arguments.joined(separator: ", ")))"
        return state + (height.map { " " + $0.rawValue } ?? "")
    }
}

enum LaunchLine {
    static let forms = "empty, reply(i), transcript(i, …), sources(i), source(i, \"group\") or weave(i, …), a height after it (`transcript(0) large`)"

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
        // What follows the state: indices, one name in quotes and one height, the brackets and commas only between.
        var indices: [Int] = []
        var quoted: String?
        var height: LaunchState.Height?
        let between: Set<Character> = [" ", ",", "(", ")"]
        var cursor = Substring(rest.dropFirst(word.count))
        while true {
            while let first = cursor.first, between.contains(first) { cursor.removeFirst() }
            guard let first = cursor.first else { break }
            if first == "\"" || first == "\u{201C}" {
                let closing: Character = first == "\"" ? "\"" : "\u{201D}"
                guard let close = cursor.dropFirst().firstIndex(of: closing) else { throw ConverseError.line(line, "its name in quotes is never closed") }
                guard quoted == nil else { throw ConverseError.line(line, "it names two things in quotes: \(name.rawValue) takes one") }
                quoted = String(cursor[cursor.index(after: cursor.startIndex)..<close])
                cursor = cursor[cursor.index(after: close)...]
            } else {
                let token = cursor.prefix { !between.contains($0) }
                cursor = cursor.dropFirst(token.count)
                if let index = Int(token), index >= 0 {
                    indices.append(index)
                } else if let named = LaunchState.Height(rawValue: token.lowercased()) {
                    guard height == nil else { throw ConverseError.line(line, "it gives two heights: a sheet opens at one, medium or large") }
                    height = named
                } else {
                    throw ConverseError.line(line, "`\(token)` is not an exchange's index (0 is the first), a name in quotes or a height (medium, large)")
                }
            }
        }
        switch name {
        case .empty:
            guard indices.isEmpty, quoted == nil else { throw ConverseError.line(line, "empty opens with no exchange, so it takes nothing") }
        case .reply, .sources:
            guard quoted == nil else { throw ConverseError.line(line, "\(name.rawValue) takes one index and nothing in quotes") }
            guard indices.count <= 1 else { throw ConverseError.line(line, "\(name.rawValue) opens one exchange: `\(name.rawValue)(0)`") }
            if indices.isEmpty { indices = [0] }
        case .transcript:
            guard quoted == nil else { throw ConverseError.line(line, "transcript takes indices and nothing in quotes") }
            guard !indices.isEmpty else { throw ConverseError.line(line, "transcript names the exchanges it holds: `transcript(0)`") }
        case .weave:
            guard !indices.isEmpty else { throw ConverseError.line(line, "weave names the exchanges its transcript holds: `weave(0)`") }
            if quoted?.isEmpty == true { throw ConverseError.line(line, "weave opens a reading by its word, in quotes: `weave(0, \"outward\")`") }
        case .source:
            guard let named = quoted, !named.isEmpty else {
                throw ConverseError.line(line, "source names the group it opens, in quotes: `source(0, \"Orbital Mechanics\")`")
            }
            guard indices.count <= 1 else { throw ConverseError.line(line, "source opens one exchange's group: `source(0, \"\(named)\")`") }
            if indices.isEmpty { indices = [0] }
        }
        if let height, name == .empty || name == .reply {
            throw ConverseError.line(line, "\(name.rawValue) opens no sheet, so it takes no height (`\(height.rawValue)`)")
        }
        return (destination, LaunchState(name: name, indices: indices, quoted: quoted, height: height))
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
