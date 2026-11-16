//  WHAT: A template's placeholders filled from the call's values, each in the form Swift reads it:
//
//            {{n:reveal.base}}           a tuning key's number, as written; `{{n:arrive.curve}}` writes all of them
//            {{n:echoes.rule#0}}         one number of several
//            {{-n:leave.rise}}           the number below zero
//            {{c:orb.inner}}             a colour: `Color(red: 70 / 255, green: 50 / 255, blue: 110 / 255)`
//            {{s:echoes.title}}          a word as a string literal
//            {{s:sources.royalty|owner.royalty}}    a word that shows a number: `"Royalty: \(owner.royalty)%"`
//            {{y:close}}                 an SF Symbol's name as a string literal
//
//  PIN:  A PLACEHOLDER NO KEY ANSWERS IS A FAULT OF THE TEMPLATE, thrown and caught by the tests before any call.

import Foundation

/// Every value a template reads: the call's, over the defaults.
struct KitValues: Sendable, Equatable {
    var tuning: [String: TuningValue]
    var strings: [String: String]
    var symbols: [String: String]

    /// The defaults: Seer's numbers, plain English words, the usual symbols.
    static var defaults: KitValues {
        var tuning: [String: TuningValue] = [:]
        for key in TuningKey.all {
            if case .success(let value) = TuningValue.read(key.fallback, as: key.kind) { tuning[key.name] = value }
        }
        var strings: [String: String] = [:]
        for key in StringKey.all { strings[key.name] = key.fallback }
        var symbols: [String: String] = [:]
        for key in SymbolKey.all { symbols[key.name] = key.fallback }
        return KitValues(tuning: tuning, strings: strings, symbols: symbols)
    }
}

enum TemplateFill {
    enum Failure: Error, Equatable, CustomStringConvertible {
        case unknown(String)
        case shape(String)

        var description: String {
            switch self {
            case .unknown(let placeholder): return "the template names \(placeholder), and no key answers it"
            case .shape(let placeholder): return "\(placeholder) does not fit its key's value"
            }
        }
    }

    static let pattern = #"\{\{(-?)([ncsy]):([A-Za-z0-9_.]+)(?:#([0-9]+))?(?:\|([^}]*))?\}\}"#

    static func fill(_ text: String, with values: KitValues) throws -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let source = text as NSString
        var out = ""
        var last = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: source.length)) {
            out += source.substring(with: NSRange(location: last, length: match.range.location - last))
            func group(_ index: Int) -> String? {
                let range = match.range(at: index)
                return range.location == NSNotFound ? nil : source.substring(with: range)
            }
            let whole = source.substring(with: match.range)
            let negate = group(1) == "-"
            let kind = group(2) ?? ""
            let key = group(3) ?? ""
            let element = group(4).flatMap { Int($0) }
            let expression = group(5)
            switch kind {
            case "n":
                guard let numbers = values.tuning[key]?.numbers, !numbers.isEmpty else { throw Failure.unknown(whole) }
                var text: String
                if let element {
                    guard element < numbers.count else { throw Failure.shape(whole) }
                    text = numbers[element]
                } else {
                    text = numbers.joined(separator: ", ")
                }
                if negate {
                    guard element != nil || numbers.count == 1 else { throw Failure.shape(whole) }
                    text = text.hasPrefix("-") ? String(text.dropFirst()) : (Double(text) == 0 ? text : "-" + text)
                }
                out += text
            case "c":
                guard let colors = values.tuning[key]?.colors, !colors.isEmpty else { throw Failure.unknown(whole) }
                out += colors[min(element ?? 0, colors.count - 1)].swift
            case "s":
                guard let word = values.strings[key] else { throw Failure.unknown(whole) }
                out += expression.map { SwiftLiteral.counted(word, $0) } ?? SwiftLiteral.string(word)
            case "y":
                guard let name = values.symbols[key] else { throw Failure.unknown(whole) }
                out += SwiftLiteral.string(name)
            default:
                throw Failure.unknown(whole)
            }
            last = match.range.location + match.range.length
        }
        out += source.substring(from: last)
        return out
    }

    /// Every placeholder `text` names, as `kind:key`.
    static func placeholders(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let source = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: source.length)).map {
            source.substring(with: $0.range(at: 2)) + ":" + source.substring(with: $0.range(at: 3))
        }
    }
}
