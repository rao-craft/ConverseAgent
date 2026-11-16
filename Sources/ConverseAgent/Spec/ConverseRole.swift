//  WHAT: The roles a mapping line gives an app's type, and what each shows: an exchange (its prompt, reply, phrases
//        and owners), a highlight (a phrase and whose it is), an owner (a name, a royalty, documents and groups), a
//        group of documents, a document (an id, its text, its influence) and a reading of the weave.
//  PIN:  ONE PROTOCOL A ROLE, ONE REQUIREMENT. `ConverseExchangeRepresentable` asks only `converseExchange`, the kit's
//        own value, so a conformance is one computed property and the views never see the app's types.

import Foundation

enum ConverseRole: String, CaseIterable, Sendable {
    case exchange, highlight, owner, group, document, reading

    static func named(_ text: String) -> ConverseRole? { ConverseRole(rawValue: text.lowercased()) }

    /// The article a sentence puts before it: `an` exchange, `a` highlight.
    var article: String { "aeiou".contains(rawValue.prefix(1)) ? "an" : "a" }
    /// The role with its article, as a sentence says it: `an exchange`, `a highlight`.
    var spoken: String { article + " " + rawValue }
    /// As a type name says it: `Exchange`.
    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    /// The kit's value: `ConverseExchange`, or `VoidExchange` with the prefix `Void`.
    func valueType(_ prefix: String = "Converse") -> String { prefix + name }
    /// The protocol a mapped type conforms to: `ConverseExchangeRepresentable`.
    func protocolName(_ prefix: String = "Converse") -> String { valueType(prefix) + "Representable" }
    /// The protocol's one requirement: `converseExchange`.
    func member(_ prefix: String = "Converse") -> String { prefix.prefix(1).lowercased() + prefix.dropFirst() + name }
    /// The `ConverseValue` conversion of a list of these: `ConverseValue.owners(…)`.
    var plural: String { rawValue + "s" }
    /// Whether its value is told apart by an `id` (read off the type's own `id` unless the line says `id=`).
    var identified: Bool { self != .highlight && self != .reading }

    /// What it shows, in the order its value's initializer takes them; `id` first when it has one.
    var properties: [ConverseProperty] {
        switch self {
        case .exchange:
            return [.init("prompt", .text, "the prompt, as the person wrote it"),
                    .init("reply", .optionalText, "the reply; nothing while it is thought of"),
                    .init("highlights", .list(.highlight), "the reply's phrases and whose each is"),
                    .init("owners", .list(.owner), "whose documents shaped the reply, with their royalty")]
        case .highlight:
            return [.init("phrase", .text, "the words of the reply to brush"),
                    .init("owner", .text, "whose they are: the owner's id or name")]
        case .owner:
            return [.init("name", .text, "the owner's name"),
                    .init("royalty", .percent, "the share of the reply they earned, a whole percent (or a fraction of 1)"),
                    .init("mine", .flag, "whether it is the person's own library"),
                    .init("tone", .optionalCount, "which palette colour is theirs; their place among the reply's owners when left out"),
                    .init("documents", .list(.document), "their documents behind the reply (the Library's rows when it is mine)"),
                    .init("groups", .list(.group), "their documents in groups (an owner's rows)")]
        case .group:
            return [.init("name", .text, "the group's name"),
                    .init("summary", .text, "one line on what it holds"),
                    .init("tags", .texts, "its tags, shown as chips"),
                    .init("documents", .list(.document), "its documents behind the reply")]
        case .document:
            return [.init("text", .text, "its text; a row shows its start"),
                    .init("influence", .percent, "how much it shaped the reply, a whole percent (or a fraction of 1)")]
        case .reading:
            return [.init("word", .text, "the word the weave shows"),
                    .init("text", .text, "the reading it opens")]
        }
    }

    func property(named word: String) -> ConverseProperty? {
        properties.first { $0.key.lowercased() == word.lowercased() }
    }
}

/// One thing a role shows, and how a mapped value becomes it.
struct ConverseProperty: Sendable, Equatable {
    let key: String
    let kind: ConverseKind
    let doc: String

    init(_ key: String, _ kind: ConverseKind, _ doc: String) {
        self.key = key; self.kind = kind; self.doc = doc
    }
}

/// What a property holds: the `ConverseValue` conversion a conformance wraps a right side in, and what it shows when
/// a line leaves it out.
indirect enum ConverseKind: Sendable, Equatable {
    case text, optionalText, percent, flag, optionalCount, texts
    case list(ConverseRole)

    /// The conversion: `ConverseValue.text(…)`.
    var conversion: String {
        switch self {
        case .text: return "text"
        case .optionalText: return "optionalText"
        case .percent: return "percent"
        case .flag: return "flag"
        case .optionalCount: return "count"
        case .texts: return "texts"
        case .list(let role): return role.rawValue + "s"
        }
    }

    /// The value a line that leaves it out shows.
    var empty: String {
        switch self {
        case .text: return "\"\""
        case .optionalText, .optionalCount: return "nil"
        case .percent: return "0"
        case .flag: return "false"
        case .texts, .list: return "[]"
        }
    }

    /// What it takes, in words, for a refusal.
    var inWords: String {
        switch self {
        case .text: return "text (a String, a whole number, a UUID or a URL)"
        case .optionalText: return "text that may be missing (a String or a String?)"
        case .percent: return "a share (a whole percent, or a Double: 0.62 or 62)"
        case .flag: return "a flag (a Bool)"
        case .optionalCount: return "a whole number (an Int)"
        case .texts: return "words (a [String], or one String split at commas)"
        case .list(let role): return "a list of values \(role.article) `\(role.rawValue):` line maps"
        }
    }

    /// The field types the conversion's overloads take, optional or not.
    var takes: Set<String> {
        let integers: Set<String> = ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]
        switch self {
        case .text: return integers.union(["String", "Substring", "UUID", "URL"])
        case .optionalText: return ["String", "Substring"]
        case .percent: return integers.union(["Double", "Float", "CGFloat", "Decimal"])
        case .flag: return ["Bool"]
        case .optionalCount: return integers
        case .texts: return ["[String]", "String", "[Substring]"]
        case .list: return []
        }
    }
}
