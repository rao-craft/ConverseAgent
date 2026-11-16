//  WHAT: The lines that set words, symbols and the look, several to a line between commas:
//
//            strings:  echoes.title = "Echoes", sources.royalty = "Royalty: {n}%"
//            symbols:  leading = infinity, weave = bonjour
//            look:     title = Font.brandTitle, accent = Color.accent, card = #FFFFFF / #FFFFFF 0.10
//
//  PIN:  A WORD IS KEPT AS QUOTED. `" speak into the void..."` keeps its leading space; a word without quotes is
//        trimmed. A key that shows a number says where with `{n}`, and a key that shows none is refused one.

import Foundation

enum WordLines {
    /// `key = value` pieces of a line: cut at commas outside quotes and brackets, a piece with no `=` going on the
    /// value before it (an unquoted word that holds a comma).
    static func pieces(_ line: String) throws -> [(key: String, value: String)] {
        var pieces: [(key: String, value: String)] = []
        for piece in LineSplit.top(line, on: ",") {
            if let equals = LineSplit.firstTop(piece, "=") {
                let key = piece[..<equals].trimmingCharacters(in: .whitespaces)
                let value = String(piece[piece.index(after: equals)...]).trimmingCharacters(in: .whitespaces)
                if key.range(of: #"^[A-Za-z][A-Za-z0-9_.]*$"#, options: .regularExpression) != nil {
                    pieces.append((key, value))
                    continue
                }
            }
            guard !pieces.isEmpty else { throw ConverseError.line(line, "`\(piece)` is not `key = value`") }
            pieces[pieces.count - 1].value += ", " + piece
        }
        guard !pieces.isEmpty else { throw ConverseError.line(line, "it is empty") }
        return pieces
    }

    /// A word as written: a quoted string read with its escapes, or bare text trimmed.
    static func word(_ value: String) -> LineRead<String> {
        let text = value.trimmingCharacters(in: .whitespaces)
        guard let first = text.first, first == "\"" || first == "\u{201C}" else { return .success(text) }
        let closing: Character = first == "\"" ? "\"" : "\u{201D}"
        var out = ""
        var escaped = false
        var index = text.index(after: text.startIndex)
        while index < text.endIndex {
            let character = text[index]
            if escaped {
                switch character {
                case "n": out.append("\n")
                case "t": out.append("\t")
                default: out.append(character)
                }
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == closing {
                let after = text[text.index(after: index)...].trimmingCharacters(in: .whitespaces)
                return after.isEmpty ? .success(out) : .failure("`\(after)` follows the closing quote")
            } else {
                out.append(character)
            }
            index = text.index(after: index)
        }
        return .failure("its quote is never closed")
    }

    static func strings(_ line: String) throws -> [(key: StringKey, text: String)] {
        var read: [(key: StringKey, text: String)] = []
        for piece in try pieces(line) {
            guard let key = StringKey.named(piece.key) else {
                throw ConverseError.line(line, "`\(piece.key)` is not a string key: the keys are " + StringKey.all.map(\.name).joined(separator: ", "))
            }
            let text: String
            switch word(piece.value) {
            case .success(let value): text = value
            case .failure(let reason): throw ConverseError.line(line, "\(key.name): \(reason)")
            }
            if key.counted, !text.contains("{n}") {
                throw ConverseError.line(line, "\(key.name) shows a number: write {n} where it goes, like `\(key.name) = \"\(key.fallback)\"`")
            }
            if !key.counted, text.contains("{n}") {
                throw ConverseError.line(line, "\(key.name) shows no number, so `{n}` would be shown as it is")
            }
            if read.contains(where: { $0.key == key }) { throw ConverseError.line(line, "`\(key.name)` is set twice") }
            read.append((key, text))
        }
        return read
    }

    static func symbols(_ line: String) throws -> [(key: SymbolKey, name: String)] {
        var read: [(key: SymbolKey, name: String)] = []
        for piece in try pieces(line) {
            guard let key = SymbolKey.named(piece.key) else {
                throw ConverseError.line(line, "`\(piece.key)` is not a symbol key: the keys are " + SymbolKey.all.map(\.name).joined(separator: ", "))
            }
            var name = piece.value
            if case .success(let unquoted) = word(name) { name = unquoted }
            guard name.range(of: #"^[a-z0-9]+(\.[a-z0-9]+)*$"#, options: .regularExpression) != nil else {
                throw ConverseError.line(line, "`\(name)` is not an SF Symbol name (lowercase words between dots, like `\(key.fallback)`)")
            }
            if read.contains(where: { $0.key == key }) { throw ConverseError.line(line, "`\(key.name)` is set twice") }
            read.append((key, name))
        }
        return read
    }

    static func look(_ line: String) throws -> [(role: LookRole, swift: String)] {
        var read: [(role: LookRole, swift: String)] = []
        for piece in try pieces(line) {
            guard let role = LookRole.named(piece.key) else {
                throw ConverseError.line(line, "`\(piece.key)` is not a look role: the roles are " + LookRole.all.map(\.name).joined(separator: ", "))
            }
            var value = piece.value
            if case .success(let unquoted) = word(value), value.hasPrefix("\"") { value = unquoted }
            guard !value.isEmpty else { throw ConverseError.line(line, "\(role.name) has `=` and no value") }
            let swift: String
            if !role.isFont, isColorLiteral(value) {
                switch colorSwift(value) {
                case .success(let text): swift = text
                case .failure(let reason): throw ConverseError.line(line, "\(role.name): \(reason)")
                }
            } else {
                guard isExpression(value) else {
                    throw ConverseError.line(line, "`\(value)` is not Swift for a \(role.isFont ? "font" : "colour"): name the app's own, like `\(role.isFont ? "Font.brand" + role.name.prefix(1).uppercased() + role.name.dropFirst() : "Color." + role.name)`"
                                             + (role.isFont ? "" : ", or give a colour: #AE9060, or #FFFFFF / #1C1C1E for light and dark"))
                }
                swift = value
            }
            if read.contains(where: { $0.role == role }) { throw ConverseError.line(line, "`\(role.name)` is set twice") }
            read.append((role, swift))
        }
        return read
    }

    /// A colour given as a value: `#AE9060`, `rgb(…)`, `(…)`, `clear`, or a light and a dark one between `/`.
    static func isColorLiteral(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.hasPrefix("#") || lower.hasPrefix("rgb") || lower.hasPrefix("(") || lower.hasPrefix("0x") || lower == "clear" || text.contains(" / ")
    }

    /// Swift for a colour value: one, or one in light and one in dark, each with an opacity after it.
    static func colorSwift(_ text: String) -> LineRead<String> {
        let sides = text.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard sides.count == 1 || sides.count == 2 else { return .failure("`\(text)` is a light and a dark colour at most, between one `/`") }
        var swift: [String] = []
        for side in sides {
            if side.lowercased() == "clear" { swift.append(".clear"); continue }
            // An opacity after the colour: `#8E8E8E 0.14`.
            var colorText = side
            var opacity: String?
            if let last = side.split(separator: " ").last, side.split(separator: " ").count > 1, let number = TuningValue.literal(String(last)),
               !side.hasSuffix(")") {
                opacity = number
                colorText = String(side.dropLast(last.count)).trimmingCharacters(in: .whitespaces)
            }
            switch TuningColor.list(colorText) {
            case .success(let colors) where colors.count == 1:
                swift.append(colors[0].swift + (opacity.map { ".opacity(\($0))" } ?? ""))
            case .success: return .failure("`\(side)` is not one colour")
            case .failure(let reason): return .failure(reason)
            }
        }
        return .success(swift.count == 1 ? swift[0] : "ConverseLook.dynamic(light: \(swift[0]), dark: \(swift[1]))")
    }

    /// Swift that reads as one expression: a name, a member, a call; brackets and quotes balanced, one line.
    static func isExpression(_ text: String) -> Bool {
        guard !text.contains("\n"), !text.contains(";"), let first = text.first, first.isLetter || first == "." || first == "_" else { return false }
        var depth = 0, quoted = false
        for character in text {
            if character == "\"" { quoted.toggle(); continue }
            if quoted { continue }
            if "([{".contains(character) { depth += 1 }
            if ")]}".contains(character) { depth -= 1; if depth < 0 { return false } }
        }
        return depth == 0 && !quoted
    }
}
