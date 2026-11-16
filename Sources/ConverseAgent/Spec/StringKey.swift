//  WHAT: Every word the views show, by key, with a natural English default. A call sets any of them with `strings`
//        lines (`echoes.title = "Echoes"`); a key that shows a number says where with `{n}` (`"Royalty: {n}%"`).

import Foundation

struct StringKey: Sendable, Equatable {
    let name: String
    let fallback: String
    let doc: String

    /// Whether it shows a number, written `{n}`.
    var counted: Bool { fallback.contains("{n}") }

    static func key(_ name: String, _ fallback: String, _ doc: String) -> StringKey { StringKey(name: name, fallback: fallback, doc: doc) }

    static func named(_ name: String) -> StringKey? { all.first { $0.name.lowercased() == name.lowercased() } }

    static let all: [StringKey] = [
        key("stage.title", "Conversation", "the stage's title in the bar; empty for none"),
        key("stage.placeholder", "Ask anything...", "the input's placeholder"),
        key("stage.cursor", " |", "the cursor after the text a reply has shown so far"),
        key("stage.echoesLabel", "Show the conversation", "the label of the bar button that opens and closes the transcript"),
        key("stage.leadingLabel", "More", "the label of the bar's leading button"),
        key("stage.keyboardLabel", "Hide keyboard", "the label of the button that drops the keyboard"),
        key("stage.sendLabel", "Send", "the send button's label"),
        key("stage.listenLabel", "Speak", "the microphone's label, when the page gives `listen`"),
        key("echoes.title", "Transcript", "the transcript's title"),
        key("echoes.copy", "Copy to clipboard", "the long press's action on a prompt or a reply"),
        key("echoes.weaveLabel", "Show the weave", "the label of the transcript's leading button, which opens the weave"),
        key("close", "Close", "the label of a sheet's close button"),
        key("sources.title", "Sources", "the sources sheet's title"),
        key("sources.library", "Library", "the header of the person's own documents"),
        key("sources.royalty", "Royalty: {n}%", "an owner's share of the reply"),
        key("sources.influence", "Influence: {n}%", "a document's share"),
        key("sources.docs", "{n} docs", "a group's count of documents"),
        key("sources.doc", "1 doc", "a group of one document"),
        key("sources.more", "...", "what follows a document's cut text"),
        key("sources.emptyTitle", "No Sources", "the title when no one's documents shaped the reply"),
        key("sources.emptyText", "Nothing in anyone's library shaped this reply.", "the line under it"),
        key("detail.title", "Documents", "a group's documents' title"),
        key("weave.title", "The Weave", "the weave's title"),
        key("weave.separator", "  ·  ", "what stands between the weave's words"),
    ]
}

/// Every SF Symbol the views draw, by key.
struct SymbolKey: Sendable, Equatable {
    let name: String
    let fallback: String
    let doc: String

    static func key(_ name: String, _ fallback: String, _ doc: String) -> SymbolKey { SymbolKey(name: name, fallback: fallback, doc: doc) }

    static func named(_ name: String) -> SymbolKey? { all.first { $0.name.lowercased() == name.lowercased() } }

    static let all: [SymbolKey] = [
        key("leading", "sparkles", "the bar's leading button, when the page gives `leading`"),
        key("echoes", "line.3.horizontal", "the bar button that opens the transcript"),
        key("close", "xmark", "a sheet's close button, and the bar button while the transcript is open"),
        key("keyboard", "chevron.down", "the bar button that drops the keyboard"),
        key("send", "arrow.up", "the send button"),
        key("listen", "mic", "the microphone, when the page gives `listen`"),
        key("listening", "mic.fill", "the microphone while it listens"),
        key("weave", "bonjour", "the transcript's leading button, which opens the weave"),
        key("copy", "document.on.clipboard", "the long press's copy action"),
        key("document", "text.document.fill", "a document's indicator"),
        key("person", "person.fill", "an owner's indicator"),
        key("empty", "magnifyingglass", "the empty sources sheet"),
    ]
}

/// The look's roles: fonts and colours the views read from `ConverseLook`, each mapped to the app's own name or left
/// to the system.
struct LookRole: Sendable, Equatable {
    let name: String
    let isFont: Bool
    /// Swift for the system's own, when the call maps nothing.
    let fallback: String
    let doc: String

    static func font(_ name: String, _ fallback: String, _ doc: String) -> LookRole { LookRole(name: name, isFont: true, fallback: fallback, doc: doc) }
    static func color(_ name: String, _ fallback: String, _ doc: String) -> LookRole { LookRole(name: name, isFont: false, fallback: fallback, doc: doc) }

    static func named(_ name: String) -> LookRole? { all.first { $0.name.lowercased() == name.lowercased() } }

    static let all: [LookRole] = [
        font("title", ".system(size: 24, design: .serif)", "bar titles"),
        font("body", ".system(size: 20, design: .serif)", "the stage's prompt, a row's word in the weave"),
        font("body2", ".system(size: 18, design: .serif)", "the transcript's prompts, a group's name"),
        font("note", ".system(size: 18, weight: .light, design: .serif)", "the stage's reply, the empty sources line"),
        font("note2", ".system(size: 16, weight: .light, design: .serif)", "the transcript's replies, a group's summary"),
        color("accent", "Color.accentColor", "bar buttons, chips"),
        color("background", "ConverseLook.system", "behind the stage"),
        color("card", "ConverseLook.dynamic(light: Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255), dark: Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255).opacity(0.10))", "an indicator's face"),
        color("cardShadow", "ConverseLook.dynamic(light: Color(red: 142 / 255, green: 142 / 255, blue: 142 / 255).opacity(0.14), dark: .clear)", "the pill's shadow"),
        color("buttonShadow", "ConverseLook.dynamic(light: Color(red: 142 / 255, green: 142 / 255, blue: 142 / 255).opacity(0.40), dark: .clear)", "an indicator's shadow"),
    ]
}
