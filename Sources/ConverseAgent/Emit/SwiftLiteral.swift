//  WHAT: Words written into Swift: a string literal with its quotes, backslashes and line breaks escaped, and one
//        that shows a number where the word says `{n}`.

import Foundation

enum SwiftLiteral {
    /// `text` as a Swift string literal.
    static func string(_ text: String) -> String {
        var out = "\""
        for character in text {
            switch character {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default: out.append(character)
            }
        }
        return out + "\""
    }

    /// `text` as a Swift string literal, each `{n}` an interpolation of `expression`: `"Royalty: \(owner.royalty)%"`.
    static func counted(_ text: String, _ expression: String) -> String {
        let parts = text.components(separatedBy: "{n}")
        let escaped = parts.map { String(string($0).dropFirst().dropLast()) }
        return "\"" + escaped.joined(separator: "\\(\(expression))") + "\""
    }
}
