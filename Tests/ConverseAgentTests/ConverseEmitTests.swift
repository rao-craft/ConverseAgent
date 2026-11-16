import Foundation
import XCTest
@testable import ConverseAgent

/// What a call writes: which files and names, the Seer call's output held to the code facts its screens are checked
/// by, the same bytes on a second run, a prefix carried through, and the app's types read and checked.
final class ConverseEmitTests: XCTestCase {
    // MARK: Files and names

    func testTheSeerCallWritesTheWholeKitAndOneConformanceALine() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.seer(into: folder)
        let kit = folder.appendingPathComponent("Components/Converse").path + "/"
        let names = result.paths.map { String($0.dropFirst(kit.count)) }
        XCTAssertEqual(names, [
            "ConverseValues.swift", "ConversePlatform.swift", "ConverseOrb.swift", "ConverseDots.swift", "ConverseGlassEdge.swift",
            "ConversePill.swift", "ConverseReplyText.swift", "ConverseStroke.swift", "ConverseFlowLayout.swift", "ConverseBrushedReply.swift",
            "ConverseExchangeView.swift", "ConverseIndicator.swift", "ConverseSources.swift", "ConverseSourceDetail.swift",
            "ConverseWeaveCanvas.swift", "ConverseWeave.swift", "ConverseTranscript.swift", "ConverseStage.swift", "ConverseSamples.swift",
            "ConverseLook.swift", "ConverseLaunch.swift", "ConverseReadings.swift",
            "Conformances/Exchange+ConverseExchange.swift", "Conformances/Highlight+ConverseHighlight.swift",
            "Conformances/Owner+ConverseOwner.swift", "Conformances/SourceGroup+ConverseGroup.swift",
            "Conformances/SourceDocument+ConverseDocument.swift",
        ])
        XCTAssertEqual(result.expected.map(\.name), ["ConverseStage", "ConverseTranscript", "ConverseSources", "ConverseSourceDetail", "ConverseWeave",
                                                     "Exchange", "Highlight", "Owner", "SourceGroup", "SourceDocument"])
        XCTAssertEqual(result.initializers.count, 5)
        XCTAssertTrue(result.notes.contains { $0.hasPrefix("A page shows the stage as the root of its navigation stack") })
        XCTAssertTrue(result.notes.contains { $0.contains("seer, void.reply, echoes, contributions, contribution, threads") })
        XCTAssertFalse(result.notes.contains { $0.hasPrefix("The look uses the system's") }, "the Seer call maps every role")
        // Plain SwiftUI: no Granite, and no state outside a view (a `static var` is computed, a `static let` constant).
        let all = try Fixture.all(result.paths)
        XCTAssertFalse(all.contains("import Granite"), "no Granite import")
        let stored = try NSRegularExpression(pattern: #"(?m)^\s*(?:(?:private|fileprivate|public|internal|nonisolated\(unsafe\))\s+)*(?:static\s+var\s+\w+\s*(?::[^{=\n]+)?=|var\s+\w+\s*(?::[^{=\n]+)?=)"#)
        for path in result.paths {
            let text = try String(contentsOfFile: path, encoding: .utf8)
            let topLevel = text.components(separatedBy: "\n").filter { $0.hasPrefix("var ") || $0.hasPrefix("private var ") || $0.hasPrefix("fileprivate var ") }
            XCTAssertEqual(topLevel, [], "\(path) declares a global variable")
            let statics = stored.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
                .filter { $0.contains("static") }
            XCTAssertEqual(statics, [], "\(path) keeps a stored static var")
        }
    }

    func testAConformanceReadsEachMappedWordThroughItsConversion() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.seer(into: folder)
        XCTAssertEqual(try Fixture.text(result.paths, "Owner+ConverseOwner.swift"), """
        import Foundation
        import SeerKit

        /// `owner: Owner name=name royalty=royalty mine=isAccount tone=tone documents=documents groups=groups`
        extension Owner: ConverseOwnerRepresentable {
            var converseOwner: ConverseOwner {
                let value = self
                return ConverseOwner(
                    id: ConverseValue.text(value.id),
                    name: ConverseValue.text(value.name),
                    royalty: ConverseValue.percent(value.royalty),
                    mine: ConverseValue.flag(value.isAccount),
                    tone: ConverseValue.count(value.tone),
                    documents: ConverseValue.documents(value.documents),
                    groups: ConverseValue.groups(value.groups)
                )
            }
        }

        """)
        let highlight = try Fixture.text(result.paths, "Highlight+ConverseHighlight.swift")
        XCTAssertTrue(highlight.contains("owner: ConverseValue.text(value.ownerId)"))
        XCTAssertFalse(highlight.contains("id:"), "a highlight has no id")
    }

    func testTheLaunchFileHasOneCaseALineAndReadsTheDestinationDefault() throws {
        let folder = try Fixture.folder()
        let launch = try Fixture.text(try Fixture.seer(into: folder).paths, "ConverseLaunch.swift")
        XCTAssertTrue(launch.contains(#"switch UserDefaults.standard.string(forKey: "destination") {"#))
        for line in [#"case "seer": return .empty"#, #"case "void.reply": return .reply(0)"#, #"case "echoes": return .transcript([0, 1, 2])"#,
                     #"case "contributions": return .sources(0)"#, #"case "contribution": return .source(0, "Orbital Mechanics")"#,
                     #"case "threads": return .weave([0, 1, 2])"#] {
            XCTAssertTrue(launch.contains(line), line)
        }
        let none = try ConverseAgent.write(.init(directory: try Fixture.folder().path), note: { _ in }, yield: { _ in })
        let empty = try Fixture.text(none.paths, "ConverseLaunch.swift")
        XCTAssertFalse(empty.contains("case \""), "no destination, no case")
        XCTAssertTrue(empty.contains("default: return nil"))
    }

    // MARK: The Seer call's output

    /// The code facts the scorecard reads off the app's Swift for the Void, Echoes, Contributions and Sinatra Threads.
    static let codeFacts: [(id: String, all: [String])] = [
        ("B-void-6", [#"speak into the void\.\.\."#, #"glassEffect\("#, #"cornerRadius:\s*24\b"#]),
        ("B-void-7", [#"\b460\b"#]),
        ("B-void-8", [#"random\(in:\s*(0(\.0)?\s*\.\.[.<]\s*(10(\.0)?|0\.010?|10_000_000)|15(\.0)?\s*\.\.[.<]\s*25(\.0)?|0\.015\s*\.\.[.<]\s*0\.025|15_000_000\s*\.\.[.<]\s*25_000_000)\s*[,)]"#]),
        ("B-void-9", [#"\b1\.2\b|\b1_?200\b|\b1_200_000_000\b"#]),
        ("B-void-10", [#" \|""#, #"\b0\.55\b|\b550\b|\b550_000_000\b"#]),
        ("B-void-11", [#"opacity\(0\.20?\)"#, #"easeIn\(duration:\s*0\.7\)"#, #"\*\s*0\.15\b|\b0\.15\s*\*"#]),
        ("B-void-12", [#"easeIn\(duration:\s*1(\.0)?\)"#, #"\b0\.96\b"#, #"-\s*30\b"#, #"\b1\.1\b|\b1_?100\b|\b1_100_000_000\b"#]),
        ("B-void-13", [#"timingCurve\(0\.16,\s*1(\.0)?,\s*0\.3,\s*1(\.0)?,\s*duration:\s*0\.9\)"#]),
        ("B-void-14", [#"\b0\.045\b"#, #"endRadius:\s*250\b"#, #"duration:\s*30\b"#]),
        ("B-void-15", [#"0\.38\D{1,40}0\.55\D{1,40}0\.38"#, #"0\.56\D{1,40}0\.49\D{1,40}0\.32"#, #"0\.94\D{1,40}0\.56\D{1,40}0\.68"#]),
        ("B-void-16", [#""infinity""#, #"line\.3\.horizontal"#, #"chevron\.down"#, #"Show conversation echoes"#]),
        ("B-echoes-5", [#"Copy to clipboard"#, #"document\.on\.clipboard"#]),
        ("B-echoes-6", [#""bonjour""#]),
        ("B-echoes-7", [#"width:\s*16,\s*height:\s*1\b"#]),
        ("B-echoes-8", [#"presentationDetents\(\s*\[\s*\.medium\s*,\s*\.large\s*\]"#, #"ultraThinMaterial"#]),
        ("B-contributions-6", [#"Royalty: "#, #"Influence: "#]),
        ("B-contributions-7", [#"magnifyingglass"#, #"No Contributions"#, #"No real contributions influenced or impacted this response\."#]),
        ("B-contributions-8", [#"text\.document\.fill"#, #"person\.fill"#]),
        ("B-contributions-9", [#"\b27\b"#]),
        ("B-contributions-10", [#""Library""#, #"\.title2\b"#]),
        ("B-contributions-11", [#"Contribution Detail"#, #"contentMargins\(\s*\.vertical"#]),
        ("B-threads-5", [#"TimelineView\(\s*\.animation"#, #"\bCanvas\s*[({]"#]),
        ("B-threads-6", [#"Georgia"#]),
        ("B-threads-7", [#"The weft is running ahead of the warp\."#, #"The immediate cadence is separating from the settled rhythm\."#, #"A measured depth\."#]),
        ("B-threads-8", [#"\b0\.0118\b"#, #"\b0\.006\b"#, #"\b0\.22\b"#]),
        ("B-threads-9", [#"easeInOut\(duration:\s*0\.4\)"#]),
    ]

    func testTheSeerOutputHoldsEveryCodeFactOfItsScreens() throws {
        let text = try Fixture.all(try Fixture.seer(into: try Fixture.folder()).paths)
        for fact in Self.codeFacts {
            for pattern in fact.all {
                XCTAssertNotNil(text.range(of: pattern, options: .regularExpression), "\(fact.id): \(pattern)")
            }
        }
    }

    func testTheSeerOutputSaysEveryQuotedStringOfItsScreens() throws {
        let text = try Fixture.all(try Fixture.seer(into: try Fixture.folder()).paths)
        for quoted in ["\"Seer\"", "\" speak into the void...\"", "\"Show conversation echoes\"", "\"Echoes\"", "\"Copy to clipboard\"",
                       "\"Contributions\"", "\"Library\"", "\"Royalty: \\(", "\"Influence: \\(", " docs\"", "\"1 doc\"", "\"No Contributions\"",
                       "\"No real contributions influenced or impacted this response.\"", "\"Contribution Detail\"", "\"Your Thread\"",
                       "\"  \u{00B7}  \"", "\"outward\"", "\"shifting\"", "\"here\"", "The loom is holding the lean.\"", "nothing strained.\""] {
            XCTAssertTrue(text.contains(quoted), quoted)
        }
    }

    func testTheSameCallWritesTheSameBytes() throws {
        let folder = try Fixture.folder()
        let first = try Fixture.seer(into: folder)
        let bytes = try first.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
        let second = try Fixture.seer(into: folder)
        XCTAssertEqual(second.paths, first.paths)
        XCTAssertEqual(try second.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }, bytes)
        XCTAssertTrue(second.made.allSatisfy { $0.state == .unchanged }, "\(second.made.filter { $0.state != .unchanged })")
        XCTAssertTrue(second.notes.contains { $0.contains("held the kit already") })
        let elsewhere = try Fixture.seer(into: try Fixture.folder())
        XCTAssertEqual(try elsewhere.paths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }, bytes, "the same in any folder")
    }

    // MARK: A prefix

    func testAPrefixRenamesEveryFileAndTypeAndAFolderKeepsItsPrefix() throws {
        let folder = try Fixture.folder()
        var tutor = try Fixture.example("tutor")
        tutor.directory = folder.path
        let result = try ConverseAgent.write(tutor, note: { _ in }, yield: { _ in })
        let names = result.paths.map { URL(fileURLWithPath: $0).lastPathComponent }
        XCTAssertTrue(names.contains("TutorStage.swift"))
        XCTAssertTrue(names.contains("Turn+TutorExchange.swift"))
        XCTAssertFalse(names.contains { $0.hasPrefix("Converse") })
        let text = try Fixture.all(result.paths)
        XCTAssertNil(text.range(of: #"(?<![A-Za-z0-9_])[Cc]onverse[A-Z]"#, options: .regularExpression), "no kit name keeps Converse")
        XCTAssertTrue(text.contains("struct TutorStage<Documents: View>: View"))
        XCTAssertTrue(text.contains("extension Turn: TutorExchangeRepresentable {\n    var tutorExchange: TutorExchange {"))
        XCTAssertTrue(text.contains("static var accent: Color { Color.indigo }"))
        XCTAssertEqual(result.views.first, "TutorStage")
        XCTAssertTrue(result.initializers[0].hasPrefix("TutorStage(exchanges: [Turn], readings: [any TutorReadingRepresentable] = TutorReadings.all"))

        // A later call into the folder keeps its prefix when it names none, and is refused when it names another.
        let later = try ConverseAgent.write(.init(into: "Views/Tutor", strings: ["stage.title = \"Lessons\""], directory: folder.path),
                                            note: { _ in }, yield: { _ in })
        XCTAssertTrue(later.paths.contains { $0.hasSuffix("/TutorStage.swift") })
        let problems = Fixture.problems(.init(into: "Views/Tutor", prefix: "Coach", directory: folder.path))
        XCTAssertEqual(problems, ["prefix: Views/Tutor already holds the kit named `Tutor`: leave `prefix` out to write it again, or write into another folder"])
    }

    // MARK: The app's types

    func testEachPathIsCheckedAgainstTheAppsTypes() throws {
        let folder = try Fixture.folder()
        try """
        import Foundation

        struct Turn: Identifiable {
            let id: UUID
            var question: String
            var answer: String?
            var asked_at: Date
            var quotes: [Quote]
            var sources: [Source]
            var count: Int
        }

        struct Quote {
            var text: String
            var sourceID: UUID
        }

        struct Source {
            var title: String
            var share: Double
            var pages: [String]
        }
        """.write(to: folder.appendingPathComponent("Models.swift"), atomically: true, encoding: .utf8)
        let problems = Fixture.problems(.init(mappings: [
            "exchange: Turn prompt=question reply=answers highlights=quotes owners=sources",
            "owner: Source name=title royalty=share documents=pages",
            "document: Page text=body",
            "exchange: Turn prompt=question reply=count",
        ], directory: folder.path))
        let expected = [
            "mappings: `exchange: Turn prompt=question reply=answers highlights=quotes owners=sources`: reply=answers: `Turn` has no `answers`: its fields are id, question, answer, asked_at, quotes, sources, count",
            "mappings: `exchange: Turn prompt=question reply=answers highlights=quotes owners=sources`: highlights=quotes: `quotes` is `[Quote]`, and each `Quote` needs a line of its own: add `highlight: Quote phrase=…`",
            "mappings: `owner: Source name=title royalty=share documents=pages`: `Source` has no `id`: say which field tells one from another, like `id=title`",
            "mappings: `owner: Source name=title royalty=share documents=pages`: documents=pages: `pages` is `[String]`, and `documents` shows a list of values a `document:` line maps",
        ]
        for reason in expected { XCTAssertTrue(problems.contains(reason), "\(reason)\nin\n\(problems.joined(separator: "\n"))") }
        XCTAssertTrue(problems.contains { $0.contains("reply=count: `count` is `Int`, and it shows text that may be missing") }, problems.joined(separator: "\n"))
        XCTAssertTrue(problems.contains { $0.hasPrefix("mappings: `Turn` is mapped as exchange twice") })
    }

    func testAPathIsWrittenInTheTypesSpellingAndALocalPackageIsImported() throws {
        let folder = try Fixture.folder()
        let kit = folder.appendingPathComponent("Packages/ChatKit")
        try FileManager.default.createDirectory(at: kit.appendingPathComponent("Sources/ChatKit"), withIntermediateDirectories: true)
        try "// swift-tools-version:6.0".write(to: kit.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try """
        public struct Message: Identifiable {
            public let id: Int
            public var promptText: String
            public var replyText: String?
        }
        """.write(to: kit.appendingPathComponent("Sources/ChatKit/Message.swift"), atomically: true, encoding: .utf8)
        let result = try ConverseAgent.write(.init(mappings: ["exchange: Message prompt=prompt_text reply=reply_text"], directory: folder.path),
                                             note: { _ in }, yield: { _ in })
        let conformance = try Fixture.text(result.paths, "Message+ConverseExchange.swift")
        XCTAssertTrue(conformance.contains("import ChatKit"))
        XCTAssertTrue(conformance.contains("prompt: ConverseValue.text(value.promptText)"))
        XCTAssertTrue(conformance.contains("reply: ConverseValue.optionalText(value.replyText)"))
        XCTAssertTrue(result.notes.contains("`Message` is declared in ChatKit, so the conformances import it."))
        XCTAssertTrue(result.notes.contains("exchange prompt: `prompt_text` is `promptText` on Message."))
    }

    func testTheLeastCallWritesTheKitOverItsOwnValuesAndSaysWhatIsLeft() throws {
        let result = try ConverseAgent.write(.init(directory: try Fixture.folder().path), note: { _ in }, yield: { _ in })
        XCTAssertFalse(result.paths.contains { $0.contains("/Conformances/") })
        XCTAssertEqual(result.conformances, [])
        XCTAssertTrue(result.initializers[0].hasPrefix("ConverseStage(exchanges: [ConverseExchange], "))
        XCTAssertTrue(result.notes.contains { $0.hasPrefix("No line maps an exchange") })
        XCTAssertTrue(result.notes.contains { $0.hasPrefix("No readings were given") })
        XCTAssertTrue(result.notes.contains { $0.hasPrefix("The look uses the system's title, body, body2, note, note2, accent, background") })
        let look = try Fixture.text(result.paths, "ConverseLook.swift")
        XCTAssertTrue(look.contains("static var title: Font { .system(size: 24, design: .serif) }"))
        XCTAssertTrue(look.contains("static var background: Color { ConverseLook.system }"))
        XCTAssertTrue(try Fixture.text(result.paths, "ConverseReadings.swift").contains("static let all: [ConverseReading] = []"))
        XCTAssertTrue(try Fixture.text(result.paths, "ConverseStage.swift").contains("ConverseBarTitle(text: \"Conversation\")"))
    }

    func testAnEmptyTitleDropsTheBarTitleAndAWordIsEscaped() throws {
        let result = try ConverseAgent.write(.init(strings: ["stage.title = \"\"", #"echoes.title = "Say \"hi\"""#],
                                                   readings: [#"odd: A "quoted" \ reading"#], directory: try Fixture.folder().path),
                                             note: { _ in }, yield: { _ in })
        let stage = try Fixture.text(result.paths, "ConverseStage.swift")
        XCTAssertFalse(stage.contains("ConverseBarTitle"), "no title, no title item")
        XCTAssertTrue(try Fixture.text(result.paths, "ConverseTranscript.swift").contains(#"ConverseBarTitle(text: "Say \"hi\"")"#))
        XCTAssertTrue(try Fixture.text(result.paths, "ConverseReadings.swift").contains(#"text: "A \"quoted\" \\ reading""#))
        XCTAssertTrue(result.notes.contains("stage.title is empty, so the stage's bar shows no title."))
    }
}
