//  WHAT: A tuning value, read and written back as Swift: numbers as the call wrote them (tidied only where Swift
//        would not read them: `.5` is `0.5`, `+5` is `5`), colours as `Color(red:green:blue:)`.

import Foundation

enum TuningValue: Sendable, Equatable {
    case numbers([String])
    case colors([TuningColor])

    var numbers: [String] { if case .numbers(let values) = self { return values }; return [] }
    var colors: [TuningColor] { if case .colors(let values) = self { return values }; return [] }

    /// `text` read as `kind`, or why not.
    static func read(_ text: String, as kind: TuningKey.Kind) -> LineRead<TuningValue> {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure("it has no value") }
        switch kind {
        case .number(let signed):
            let parts = numberWords(trimmed)
            guard parts.count == 1, let number = literal(parts[0]) else { return .failure("`\(trimmed)` is not one number") }
            if !signed, number.hasPrefix("-") { return .failure("`\(trimmed)` is below zero") }
            return .success(.numbers([number]))
        case .count:
            guard trimmed.range(of: #"^\+?[0-9]+$"#, options: .regularExpression) != nil else { return .failure("`\(trimmed)` is not a whole number") }
            return .success(.numbers([String(Int(trimmed.replacingOccurrences(of: "+", with: "")) ?? 0)]))
        case .numbers(let count, let signed):
            let parts = numberWords(trimmed)
            let numbers = parts.compactMap(literal)
            guard numbers.count == parts.count, numbers.count == count else {
                return .failure("`\(trimmed)` is not \(count) numbers")
            }
            if !signed, let negative = numbers.first(where: { $0.hasPrefix("-") }) { return .failure("`\(negative)` is below zero") }
            return .success(.numbers(numbers))
        case .color:
            switch TuningColor.list(trimmed) {
            case .success(let colors) where colors.count == 1: return .success(.colors(colors))
            case .success: return .failure("`\(trimmed)` is more than one colour")
            case .failure(let reason): return .failure(reason)
            }
        case .colors:
            switch TuningColor.list(trimmed) {
            case .success(let colors) where !colors.isEmpty: return .success(.colors(colors))
            case .success: return .failure("`\(trimmed)` holds no colour")
            case .failure(let reason): return .failure(reason)
            }
        }
    }

    /// The numbers of `0.16, 1 0.3,1`: cut at spaces and commas.
    static func numberWords(_ text: String) -> [String] {
        text.split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\t" }).map(String.init)
    }

    /// A number as Swift reads it, or nil: `.5` is `0.5`, `+5` is `5`, `5.` is `5`.
    static func literal(_ word: String) -> String? {
        var text = word
        var sign = ""
        if text.hasPrefix("+") { text.removeFirst() } else if text.hasPrefix("-") || text.hasPrefix("−") { text.removeFirst(); sign = "-" }
        if text.hasPrefix(".") { text = "0" + text }
        if text.hasSuffix(".") { text.removeLast() }
        guard text.range(of: #"^[0-9]+(\.[0-9]+)?$"#, options: .regularExpression) != nil else { return nil }
        // `-0` is zero.
        if sign == "-", Double(text) == 0 { sign = "" }
        return sign + text
    }
}

/// A colour as the call wrote it: from 0 to 1, from 0 to 255, or hex.
struct TuningColor: Sendable, Equatable {
    let red: String
    let green: String
    let blue: String
    /// Whether the components are over 255.
    let bytes: Bool

    /// `Color(red: 0.38, green: 0.55, blue: 0.38)`, or over 255: `Color(red: 70 / 255, green: 50 / 255, blue: 110 / 255)`.
    var swift: String {
        bytes ? "Color(red: \(red) / 255, green: \(green) / 255, blue: \(blue) / 255)"
              : "Color(red: \(red), green: \(green), blue: \(blue))"
    }

    /// The colours of `rgb(70, 50, 110) (0.2, 0.3, 0.4) #AE9060`, or why not.
    static func list(_ text: String) -> LineRead<[TuningColor]> {
        var colors: [TuningColor] = []
        var rest = Substring(text)
        func skip() { while let first = rest.first, first == " " || first == "," || first == "\t" { rest.removeFirst() } }
        skip()
        while !rest.isEmpty {
            if rest.lowercased().hasPrefix("rgb") { rest = rest.dropFirst(3); skip() }
            if rest.first == "(" {
                guard let close = rest.firstIndex(of: ")") else { return .failure("`\(text)` opens a colour it does not close") }
                let inside = rest[rest.index(after: rest.startIndex)..<close]
                rest = rest[rest.index(after: close)...]
                let parts = TuningValue.numberWords(String(inside))
                let numbers = parts.compactMap(TuningValue.literal)
                guard parts.count == 3, numbers.count == 3, numbers.allSatisfy({ !$0.hasPrefix("-") }) else {
                    return .failure("`(\(inside))` is not a colour: three numbers, from 0 to 1 or from 0 to 255")
                }
                let values = numbers.compactMap(Double.init)
                let bytes = values.contains { $0 > 1 }
                if bytes, values.contains(where: { $0 > 255 }) { return .failure("`(\(inside))` goes past 255") }
                colors.append(TuningColor(red: numbers[0], green: numbers[1], blue: numbers[2], bytes: bytes))
            } else {
                let word = rest.prefix { $0 != " " && $0 != "," && $0 != "\t" }
                rest = rest.dropFirst(word.count)
                var hex = String(word)
                if hex.hasPrefix("#") { hex.removeFirst() } else if hex.lowercased().hasPrefix("0x") { hex.removeFirst(2) }
                guard hex.count == 6, let value = Int(hex, radix: 16) else {
                    return .failure("`\(word)` is not a colour: rgb(r, g, b), (r, g, b) or #RRGGBB")
                }
                colors.append(TuningColor(red: String((value >> 16) & 0xFF), green: String((value >> 8) & 0xFF), blue: String(value & 0xFF), bytes: true))
            }
            skip()
        }
        return .success(colors)
    }
}
