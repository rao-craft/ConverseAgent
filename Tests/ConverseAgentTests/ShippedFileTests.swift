import Foundation
import GraniteAgents
import XCTest
@testable import ConverseAgent

/// The files the repository ships beside the code, held to it: the schemas are the record's, as `craft agents schema`
/// writes them; the reference names every field, word, key and state the lines are read against, and gives the
/// initializers and the page body the gated build uses; the Seer answer is the one the Seer call answers.
/// `CONVERSE_EXAMPLES=1` writes the schemas and the answer again.
final class ShippedFileTests: XCTestCase {
    private let converse = AnyAgentPackage(ConverseAgent.self)
    private let base = "https://github.com/rao-craft/ConverseAgent/blob/main/Schema/"

    func testTheInputSchemaIsTheRecordsFieldsAsTheModelSeesThem() throws {
        var input = try XCTUnwrap(try JSONSerialization.jsonObject(
            with: converse.schema.jsonSchema(notes: converse.fields, hiding: [AnyAgentPackage.directoryField])) as? [String: Any])
        input["$schema"] = "https://json-schema.org/draft/2020-12/schema"
        input["$id"] = base + "converse.input.schema.json"
        input["title"] = "What converse takes (craft-agent/1)"
        input["description"] = "Every field a call to converse may give; `directory` is Craft's, never the model's."
        let files = try Fixture.shipped(input, at: "Schema/converse.input.schema.json")
        XCTAssertEqual(files.shipped, files.made, "Schema/converse.input.schema.json is the record's: CONVERSE_EXAMPLES=1 writes it again")
    }

    func testTheAnswerSchemaIsGraniteAnswerWithTheKindsItMakesAndItsOwnKeys() throws {
        let item: [String: Any] = ["type": "object", "required": ["kind", "name"],
                                   "properties": ["kind": ["type": "string", "enum": ConverseAgent.makes.map(\.kind)], "name": ["type": "string"]]]
        let lines: [String: Any] = ["type": "array", "items": ["type": "string"]]
        func described(_ note: String) -> [String: Any] { lines.merging(["description": note]) { $1 } }
        let answer: [String: Any] = [
            "$schema": "https://json-schema.org/draft/2020-12/schema", "$id": base + "converse.answer.schema.json",
            "title": "What converse answers (granite-answer/1)",
            "description": "A granite-answer/1 answer; what converse makes and expects is one of its own kinds, beside the views, the conformances, each root's initializer, the launch states and the notes.",
            "allOf": [["$ref": "https://github.com/riteshpakala/Granite/blob/main/Schema/granite-agent-answer.schema.json"]],
            "properties": [
                "made": ["type": "array", "items": item], "expected": ["type": "array", "items": item],
                "path": ["type": ["string", "null"], "description": "the first file written"],
                "views": described("the views written, by type name, the five roots first"),
                "conformances": described("one line a mapped type: `Exchange: exchange`"),
                "initializers": described("each root view's initializer as one line, with the app's exchange type in it: what the host writes the page body from"),
                "launch": described("the launch states, one line a destination: `void.reply = reply(0)`"),
                "notes": described("one sentence each: what the call left out or the app still has to do"),
            ],
        ]
        let files = try Fixture.shipped(answer, at: "Schema/converse.answer.schema.json")
        XCTAssertEqual(files.shipped, files.made, "Schema/converse.answer.schema.json: CONVERSE_EXAMPLES=1 writes it again")
        let decoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(try Fixture.seer(into: Fixture.folder()))) as? [String: Any]
        for key in ["views", "conformances", "initializers", "launch", "notes", "made", "expected"] {
            XCTAssertNotNil(decoded?[key], "the answer has \(key)")
        }
    }

    /// `Converse.md` names every field, every role's words, look role, string, symbol, tuning key and launch state,
    /// each default as the code holds it, and gives the initializers and the page body the gated build compiles.
    func testTheReferenceListsEveryKeyWithItsDefault() throws {
        let reference = try String(contentsOf: Fixture.package.appendingPathComponent("Schema/Converse.md"), encoding: .utf8)
        func cell(_ text: String) -> String { text.replacingOccurrences(of: "|", with: "\\|") }
        for (field, note) in ConverseAgent.fields { XCTAssertTrue(reference.contains("| `\(field)` | no | \(cell(note)) |"), "Converse.md takes \(field)") }
        for make in ConverseAgent.makes { XCTAssertTrue(reference.contains("| `\(make.kind)` | \(cell(make.what)) |"), "Converse.md makes \(make.kind)") }
        for role in ConverseRole.allCases {
            XCTAssertTrue(reference.contains("| `\(role.rawValue)` | `"), "Converse.md maps \(role.rawValue)")
            for property in role.properties {
                XCTAssertTrue(reference.contains("| `\(property.key)` | ") && reference.contains("| \(cell(property.doc)) |"), "Converse.md says \(role).\(property.key)")
            }
        }
        for role in LookRole.all { XCTAssertTrue(reference.contains("| `\(role.name)` | \(role.isFont ? "Font" : "Color") | `\(cell(role.fallback))` |"), "Converse.md looks \(role.name)") }
        for key in StringKey.all { XCTAssertTrue(reference.contains("| `\(key.name)` | `\"\(cell(key.fallback))\"` | \(cell(key.doc)) |"), "Converse.md says \(key.name)") }
        for key in SymbolKey.all { XCTAssertTrue(reference.contains("| `\(key.name)` | `\(key.fallback)` | \(cell(key.doc)) |"), "Converse.md draws \(key.name)") }
        for key in TuningKey.all { XCTAssertTrue(reference.contains("| `\(key.name)` | `\(key.fallback)` | "), "Converse.md tunes \(key.name)") }
        for state in LaunchState.Name.allCases { XCTAssertTrue(reference.contains("| `\(state.rawValue)"), "Converse.md opens \(state.rawValue)") }
        for height in LaunchState.Height.allCases { XCTAssertTrue(reference.contains("`\(height.rawValue)`"), "Converse.md opens at \(height.rawValue)") }
        for line in try Fixture.example("seer").launch ?? [] { XCTAssertTrue(reference.contains("\n" + line + "\n"), "Converse.md launches \(line)") }
        for line in ConverseAgent.initializers(ConverseAgent.read(try Fixture.example("seer")), prefix: "Converse") {
            XCTAssertTrue(reference.contains("\n" + line + "\n"), "Converse.md gives \(line)")
        }
        XCTAssertTrue(reference.contains("\n" + ConverseApps.seerPageBody + "\n"), "Converse.md gives the page body")
    }

    /// The answer shipped for the Seer call is the one the Seer call answers through the roster, over an app whose
    /// types live in a SeerKit package, its paths relative to the project.
    func testTheShippedSeerAnswerIsTheSeerCallsAnswer() async throws {
        let folder = try Fixture.folder()
        try Fixture.write("""
            // swift-tools-version:6.0
            import PackageDescription
            let package = Package(name: "SeerKit", products: [.library(name: "SeerKit", targets: ["SeerKit"])],
                                  targets: [.target(name: "SeerKit")])
            """, to: folder.appendingPathComponent("Packages/SeerKit/Package.swift"))
        try Fixture.write(ConverseApps.seerKit, to: folder.appendingPathComponent("Packages/SeerKit/Sources/SeerKit/Models.swift"))
        // SeerKit's types are exactly these, so every mapping line below is checked against them and accepted.
        let app = AppTypes(root: folder)
        let types: [String: [String]] = [
            "Exchange": ["id String", "prompt String", "reply String", "highlights [Highlight]", "owners [Contributor]"],
            "Highlight": ["phrase String", "ownerId String"],
            "Contributor": ["ownerId String", "name String", "royalty Int", "isAccount Bool", "tone Int", "documents [SourceDocument]", "groups [SourceGroup]"],
            "SourceDocument": ["documentId String", "text String", "influence Int"],
            "SourceGroup": ["name String", "summary String", "tags [String]", "documents [SourceDocument]"],
        ]
        XCTAssertEqual(Set(app.types.keys), Set(types.keys).union(["MockExchanges"]))
        for (name, fields) in types {
            XCTAssertEqual(app.types[name]?.fields.map { "\($0.name) \($0.type)" }, fields, name)
            XCTAssertEqual(app.types[name]?.module, "SeerKit", name)
        }
        let call = try Data(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"))
        let answer = try await converse.perform(call, host: AgentHost(directory: folder.path))
        var relative = String(decoding: answer, as: UTF8.self)
        for root in Set([folder.path, folder.resolvingSymlinksInPath().path]) {
            relative = relative.replacingOccurrences(of: root.replacingOccurrences(of: "/", with: "\\/") + "\\/", with: "")
                .replacingOccurrences(of: root + "/", with: "")
        }
        XCTAssertFalse(relative.contains(folder.lastPathComponent), "no absolute path")
        let object = try JSONSerialization.jsonObject(with: Data(relative.utf8))
        let files = try Fixture.shipped(object, at: "Schema/examples/seer.answer.json")
        XCTAssertEqual(files.shipped, files.made, "Schema/examples/seer.answer.json is the Seer call's answer: CONVERSE_EXAMPLES=1 writes it again")
    }
}
