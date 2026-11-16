extension Template {
    static let values = #"""
import Foundation

// The conversation views' own values. An app's types become them through the protocols below, one computed property
// each (written into Conformances/ from the call's mapping lines), so the views never read the app's types.

/// One prompt and its reply.
struct ConverseExchange: Identifiable, Hashable, Sendable {
    var id: String
    /// The prompt, as the person wrote it.
    var prompt: String
    /// The reply; nil while it is thought of.
    var reply: String?
    /// The reply's phrases, and whose each is.
    var highlights: [ConverseHighlight]
    /// Whose documents shaped the reply, in the order that sets their colours.
    var owners: [ConverseOwner]

    init(id: String = UUID().uuidString, prompt: String = "", reply: String? = nil,
         highlights: [ConverseHighlight] = [], owners: [ConverseOwner] = []) {
        self.id = id
        self.prompt = prompt
        self.reply = reply
        self.highlights = highlights
        self.owners = owners
    }

    /// The owner a highlight names, by id or by name.
    func owner(of highlight: ConverseHighlight) -> ConverseOwner? {
        owners.first { $0.id == highlight.owner } ?? owners.first { $0.name == highlight.owner }
    }

    /// An owner's place in the palette: its own tone, else its place among the reply's owners.
    func tone(of owner: ConverseOwner) -> Int {
        owner.tone ?? owners.firstIndex { $0.id == owner.id } ?? 0
    }
}

/// A phrase of a reply, and whose it is.
struct ConverseHighlight: Hashable, Sendable {
    /// The words of the reply to brush.
    var phrase: String
    /// Whose they are: the owner's id or name.
    var owner: String

    init(phrase: String = "", owner: String = "") {
        self.phrase = phrase
        self.owner = owner
    }
}

/// Someone whose documents shaped a reply, and the share of it they earned.
struct ConverseOwner: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    /// A whole percent.
    var royalty: Int
    /// Whether it is the person's own library.
    var mine: Bool
    /// Which palette colour is theirs; their place among the reply's owners when nil.
    var tone: Int?
    /// Their documents behind the reply.
    var documents: [ConverseDocument]
    /// Their documents in groups.
    var groups: [ConverseGroup]

    init(id: String = UUID().uuidString, name: String = "", royalty: Int = 0, mine: Bool = false, tone: Int? = nil,
         documents: [ConverseDocument] = [], groups: [ConverseGroup] = []) {
        self.id = id
        self.name = name
        self.royalty = royalty
        self.mine = mine
        self.tone = tone
        self.documents = documents
        self.groups = groups
    }

    /// The groups an owner's rows show: its own, else one holding its documents.
    var shownGroups: [ConverseGroup] {
        if !groups.isEmpty { return groups }
        return documents.isEmpty ? [] : [ConverseGroup(id: id, name: name, documents: documents)]
    }

    /// The documents a Library's rows show: its own, else every group's.
    var shownDocuments: [ConverseDocument] {
        documents.isEmpty ? groups.flatMap(\.documents) : documents
    }
}

/// Documents of one owner that belong together.
struct ConverseGroup: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    /// One line on what it holds.
    var summary: String
    var tags: [String]
    var documents: [ConverseDocument]

    init(id: String = UUID().uuidString, name: String = "", summary: String = "", tags: [String] = [],
         documents: [ConverseDocument] = []) {
        self.id = id
        self.name = name
        self.summary = summary
        self.tags = tags
        self.documents = documents
    }
}

/// A document behind a reply, and how much it shaped it.
struct ConverseDocument: Identifiable, Hashable, Sendable {
    var id: String
    /// Its text; a row shows its start.
    var text: String
    /// A whole percent.
    var influence: Int

    init(id: String = UUID().uuidString, text: String = "", influence: Int = 0) {
        self.id = id
        self.text = text
        self.influence = influence
    }
}

/// A word of the weave, and the reading it opens.
struct ConverseReading: Identifiable, Hashable, Sendable {
    var id: String { word }
    var word: String
    var text: String

    init(word: String = "", text: String = "") {
        self.word = word
        self.text = text
    }
}

/// A line of the weave's legend: a quality, the indicators it is read from, and its value, as written.
struct ConverseMeasure: Identifiable, Hashable, Sendable {
    var id: String { quality }
    var quality: String
    var indicator: String
    var value: String

    init(quality: String = "", indicator: String = "", value: String = "") {
        self.quality = quality
        self.indicator = indicator
        self.value = value
    }
}

// MARK: The protocols an app's types conform to

/// A type the stage shows as an exchange.
protocol ConverseExchangeRepresentable {
    var converseExchange: ConverseExchange { get }
}

/// A type a reply's phrase is read from.
protocol ConverseHighlightRepresentable {
    var converseHighlight: ConverseHighlight { get }
}

/// A type the sources show as an owner.
protocol ConverseOwnerRepresentable {
    var converseOwner: ConverseOwner { get }
}

/// A type the sources show as a group of documents.
protocol ConverseGroupRepresentable {
    var converseGroup: ConverseGroup { get }
}

/// A type the sources show as a document.
protocol ConverseDocumentRepresentable {
    var converseDocument: ConverseDocument { get }
}

/// A type the weave shows as a word and its reading.
protocol ConverseReadingRepresentable {
    var converseReading: ConverseReading { get }
}

extension ConverseExchange: ConverseExchangeRepresentable {
    var converseExchange: ConverseExchange { self }
}

extension ConverseHighlight: ConverseHighlightRepresentable {
    var converseHighlight: ConverseHighlight { self }
}

extension ConverseOwner: ConverseOwnerRepresentable {
    var converseOwner: ConverseOwner { self }
}

extension ConverseGroup: ConverseGroupRepresentable {
    var converseGroup: ConverseGroup { self }
}

extension ConverseDocument: ConverseDocumentRepresentable {
    var converseDocument: ConverseDocument { self }
}

extension ConverseReading: ConverseReadingRepresentable {
    var converseReading: ConverseReading { self }
}

// MARK: Reading an app's fields

/// How a conformance reads an app's field, whatever its type: every right side of a mapping line goes through one of
/// these, so `royalty` may be an Int or a Double and `reply` a String or a String?.
enum ConverseValue {
    static func text(_ value: String) -> String { value }
    static func text(_ value: String?) -> String { value ?? "" }
    static func text(_ value: Substring) -> String { String(value) }
    static func text<Number: BinaryInteger>(_ value: Number) -> String { String(value) }
    static func text<Number: BinaryInteger>(_ value: Number?) -> String { value.map { String($0) } ?? "" }
    static func text(_ value: UUID) -> String { value.uuidString }
    static func text(_ value: UUID?) -> String { value?.uuidString ?? "" }
    static func text(_ value: URL) -> String { value.absoluteString }
    static func text(_ value: URL?) -> String { value?.absoluteString ?? "" }

    static func optionalText(_ value: String) -> String? { value.isEmpty ? nil : value }
    static func optionalText(_ value: String?) -> String? { value?.isEmpty == true ? nil : value }
    static func optionalText(_ value: Substring) -> String? { value.isEmpty ? nil : String(value) }

    /// A whole percent; a share of 1 (0.62) is read as its percent.
    static func percent<Number: BinaryInteger>(_ value: Number) -> Int { Int(value) }
    static func percent<Number: BinaryInteger>(_ value: Number?) -> Int { value.map { Int($0) } ?? 0 }
    static func percent<Number: BinaryFloatingPoint>(_ value: Number) -> Int {
        let share = Double(value)
        return Int((share <= 1 ? share * 100 : share).rounded())
    }
    static func percent<Number: BinaryFloatingPoint>(_ value: Number?) -> Int { value.map { percent($0) } ?? 0 }
    static func percent(_ value: Decimal) -> Int { percent(NSDecimalNumber(decimal: value).doubleValue) }

    static func flag(_ value: Bool) -> Bool { value }
    static func flag(_ value: Bool?) -> Bool { value ?? false }

    static func count<Number: BinaryInteger>(_ value: Number) -> Int? { Int(value) }
    static func count<Number: BinaryInteger>(_ value: Number?) -> Int? { value.map { Int($0) } }

    static func texts(_ value: [String]) -> [String] { value }
    static func texts(_ value: [String]?) -> [String] { value ?? [] }
    static func texts(_ value: [Substring]) -> [String] { value.map { String($0) } }
    static func texts(_ value: String) -> [String] {
        value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
    static func texts(_ value: String?) -> [String] { texts(value ?? "") }

    static func exchanges<Item: ConverseExchangeRepresentable>(_ value: [Item]) -> [ConverseExchange] { value.map(\.converseExchange) }
    static func exchanges<Item: ConverseExchangeRepresentable>(_ value: [Item]?) -> [ConverseExchange] { (value ?? []).map(\.converseExchange) }
    static func highlights<Item: ConverseHighlightRepresentable>(_ value: [Item]) -> [ConverseHighlight] { value.map(\.converseHighlight) }
    static func highlights<Item: ConverseHighlightRepresentable>(_ value: [Item]?) -> [ConverseHighlight] { (value ?? []).map(\.converseHighlight) }
    static func owners<Item: ConverseOwnerRepresentable>(_ value: [Item]) -> [ConverseOwner] { value.map(\.converseOwner) }
    static func owners<Item: ConverseOwnerRepresentable>(_ value: [Item]?) -> [ConverseOwner] { (value ?? []).map(\.converseOwner) }
    static func groups<Item: ConverseGroupRepresentable>(_ value: [Item]) -> [ConverseGroup] { value.map(\.converseGroup) }
    static func groups<Item: ConverseGroupRepresentable>(_ value: [Item]?) -> [ConverseGroup] { (value ?? []).map(\.converseGroup) }
    static func documents<Item: ConverseDocumentRepresentable>(_ value: [Item]) -> [ConverseDocument] { value.map(\.converseDocument) }
    static func documents<Item: ConverseDocumentRepresentable>(_ value: [Item]?) -> [ConverseDocument] { (value ?? []).map(\.converseDocument) }
    static func readings<Item: ConverseReadingRepresentable>(_ value: [Item]) -> [ConverseReading] { value.map(\.converseReading) }
    static func readings<Item: ConverseReadingRepresentable>(_ value: [Item]?) -> [ConverseReading] { (value ?? []).map(\.converseReading) }
}
"""#
}
