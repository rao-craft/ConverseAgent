//  WHAT: The tuning line: a group and its keys, or one key.
//
//            reveal: base 15, jitter 10, wait 1.2, cursor 0.55
//            arrive: curve 0.16 1 0.3 1, duration 0.9
//            stroke.opacity = 0.20
//            palette = (0.38, 0.55, 0.38) (0.56, 0.49, 0.32) (0.94, 0.56, 0.68)
//
//        A group, a colon, then `key value` pairs between commas; or a whole key, `=` or `:`, and its value. A piece
//        that starts with no key of its group goes on the value before it, so `curve 0.16, 1, 0.3, 1` is one value.
//  PIN:  EVERY KEY REFUSED IS NAMED WITH WHAT ITS GROUP TAKES, and a value refused says what the key holds.

import Foundation

enum TuningLine {
    static func parse(_ line: String) throws -> [(key: TuningKey, value: TuningValue)] {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ConverseError.line(line, "it is empty") }
        let colon = LineSplit.firstTop(text, ":")
        let equals = LineSplit.firstTop(text, "=")
        let cut = [colon, equals].compactMap { $0 }.min()
        var head: String
        var rest: String
        if let cut {
            head = text[..<cut].trimmingCharacters(in: .whitespaces)
            rest = text[text.index(after: cut)...].trimmingCharacters(in: .whitespaces)
        } else {
            // `reveal.base 15`: a whole key, then its value.
            let space = text.firstIndex(of: " ") ?? text.endIndex
            head = String(text[..<space])
            rest = text[space...].trimmingCharacters(in: .whitespaces)
        }
        if let key = TuningKey.named(head) {
            return [(key, try value(rest, for: key, line: line))]
        }
        // `reveal base: 15` or `reveal base 15`, a group and one key before the colon.
        let words = head.split(separator: " ").map(String.init)
        if words.count == 2, let key = TuningKey.named(words[0] + "." + words[1]) {
            return [(key, try value(rest, for: key, line: line))]
        }
        guard cut != nil, TuningKey.groups.contains(where: { $0.lowercased() == head.lowercased() }) else {
            throw ConverseError.line(line, "`\(head)` is not a tuning group or key: a line is `group: key value, key value` or `group.key = value`, and the groups are "
                                     + TuningKey.groups.joined(separator: ", "))
        }
        let group = TuningKey.groups.first { $0.lowercased() == head.lowercased() } ?? head
        let keys = TuningKey.keys(in: group)
        var pieces: [(word: String, value: String)] = []
        for piece in LineSplit.top(rest, on: ",") {
            let word = String(piece.prefix { $0.isLetter || $0.isNumber || $0 == "_" })
            if !word.isEmpty, word.first?.isLetter == true, word.lowercased() != "rgb", keys.contains(where: { $0.word.lowercased() == word.lowercased() }) {
                var value = piece.dropFirst(word.count).trimmingCharacters(in: .whitespaces)
                if value.hasPrefix("=") || value.hasPrefix(":") { value = value.dropFirst().trimmingCharacters(in: .whitespaces) }
                pieces.append((word, value))
            } else if !pieces.isEmpty, !(word.first?.isLetter == true && word.lowercased() != "rgb") {
                pieces[pieces.count - 1].value += ", " + piece
            } else {
                let named = word.isEmpty ? piece : word
                throw ConverseError.line(line, "`\(named)` is not a key of \(group): it takes " + keys.map(\.word).joined(separator: ", "))
            }
        }
        guard !pieces.isEmpty else {
            throw ConverseError.line(line, "it sets nothing: `\(group): \(keys[0].word) \(keys[0].fallback)`")
        }
        var read: [(key: TuningKey, value: TuningValue)] = []
        for piece in pieces {
            guard let key = keys.first(where: { $0.word.lowercased() == piece.word.lowercased() }) else { continue }
            if read.contains(where: { $0.key == key }) { throw ConverseError.line(line, "`\(key.name)` is set twice") }
            read.append((key, try value(piece.value, for: key, line: line)))
        }
        return read
    }

    private static func value(_ text: String, for key: TuningKey, line: String) throws -> TuningValue {
        switch TuningValue.read(text, as: key.kind) {
        case .success(let value): return value
        case .failure(let reason):
            throw ConverseError.line(line, "\(key.name) takes \(key.kind.inWords) (\(key.doc)), like `\(key.name) = \(key.fallback)`, and \(reason)")
        }
    }
}
