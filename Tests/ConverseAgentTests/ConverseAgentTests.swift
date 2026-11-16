import Foundation
import GraniteAgents
import XCTest
@testable import ConverseAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class ConverseAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let converse = try XCTUnwrap(GraniteRoster.discovered().package("converse"), "the record is in this test binary")
        XCTAssertEqual(converse.module, "ConverseAgent")
        XCTAssertEqual(converse.summary, ConverseAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let converse = AnyAgentPackage(ConverseAgent.self)
        let lines: GraniteSchema = .array(.string)
        XCTAssertEqual(converse.schema, .object([
            .init(name: "into", schema: .string, required: false),
            .init(name: "prefix", schema: .string, required: false),
            .init(name: "imports", schema: lines, required: false),
            .init(name: "mappings", schema: lines, required: false),
            .init(name: "look", schema: lines, required: false),
            .init(name: "strings", schema: lines, required: false),
            .init(name: "symbols", schema: lines, required: false),
            .init(name: "tuning", schema: lines, required: false),
            .init(name: "launch", schema: lines, required: false),
            .init(name: "readings", schema: lines, required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(converse.takesDirectory)
        XCTAssertEqual(Set(converse.fields.keys), ["into", "prefix", "imports", "mappings", "look", "strings", "symbols", "tuning", "launch", "readings"],
                       "a note beside every field the model sees")
        XCTAssertEqual(converse.lanes, 2)
        XCTAssertEqual(converse.makes.map(\.kind), ["view", "conformance"])
    }

    func testTheGuideTeachesEveryLineEveryRoleAndOneCall() {
        let guide = AnyAgentPackage(ConverseAgent.self).guide
        for word in ["mappings", "exchange (", "highlight (", "owner (", "group (", "document (", "reading (", "value", "id=", "imports",
                     "look", "strings", "symbols", "tuning", "launch", "readings", "ConverseStage(exchanges:", "send", "load", "leading",
                     "listen", "documents", "empty", "reply(i)", "transcript(i, …)", "sources(i)", "source(i, \"group\")", "weave(i, …)",
                     "weave(0, \"outward\")", "echoes.full = transcript(0) large"] {
            XCTAssertTrue(guide.contains(word), "the guide says \(word)")
        }
        // Every word a role maps is in the guide, so the model never has to guess one.
        for role in ConverseRole.allCases {
            for property in role.properties { XCTAssertTrue(guide.contains(property.key), "the guide names \(role).\(property.key)") }
        }
        XCTAssertEqual(guide.components(separatedBy: "{\"").count - 1, 1, "one example call")
        XCTAssertFalse(guide.contains("Seer"), "no Seer names to copy")
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming the files.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        let data = try Data(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"))
        var call = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        call["directory"] = folder.path
        let input = try JSONSerialization.data(withJSONObject: call)
        let answer = try await AnyAgentPackage(ConverseAgent.self).perform(input, host: AgentHost(directory: folder.path, ask: "the conversation"))
        let result = try JSONDecoder().decode(ConverseResult.self, from: answer)
        let kit = folder.appendingPathComponent("Components/Converse").path
        XCTAssertEqual(result.path, result.paths.first)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(kit + "/"), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        let names = Set(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent })
        for name in ["ConverseStage.swift", "ConverseTranscript.swift", "ConverseSources.swift", "ConverseSourceDetail.swift",
                     "ConverseWeave.swift", "ConverseLook.swift", "ConverseLaunch.swift", "ConverseReadings.swift", "ConverseValues.swift",
                     "Exchange+ConverseExchange.swift", "Highlight+ConverseHighlight.swift", "Contributor+ConverseOwner.swift",
                     "SourceGroup+ConverseGroup.swift", "SourceDocument+ConverseDocument.swift"] {
            XCTAssertTrue(names.contains(name), name)
        }
        XCTAssertEqual(result.conformances, ["Exchange: exchange", "Highlight: highlight", "Contributor: owner", "SourceGroup: group", "SourceDocument: document"])
        XCTAssertEqual(result.launch, ["seer = empty", "void.reply = reply(0)", "echoes = transcript(0)", "contributions = sources(0)",
                                       "contribution = source(0, \"Orbital Mechanics\")", "threads = weave(0)", "echoes.full = transcript(0) large",
                                       "contributions.full = sources(0) large", "threads.full = weave(0) large"])
        XCTAssertEqual(result.views.prefix(5), ["ConverseStage", "ConverseTranscript", "ConverseSources", "ConverseSourceDetail", "ConverseWeave"])
        XCTAssertTrue(result.initializers[0].hasPrefix("ConverseStage(exchanges: [Exchange], "), result.initializers[0])
        let made = Set(result.made.map(\.name))
        for expected in result.expected { XCTAssertTrue(made.contains(expected.name), "\(expected.name) is made") }
        XCTAssertTrue(result.made.allSatisfy { $0.state == .written })
    }

    /// A host over the wire may name its folder only in `AgentHost`: every file lands there all the same.
    func testTheHostsFolderIsUsedWhenTheCallNamesNone() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["mappings": ["exchange: Turn prompt=question reply=answer"]])
        let answer = try await AnyAgentPackage(ConverseAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(ConverseResult.self, from: answer)
        XCTAssertFalse(result.paths.isEmpty)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path + "/"), "\(path) is not under the host's folder")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
    }

    /// A call refused over the wire says every reason, as the call's to fix.
    func testARefusedCallSaysEveryReasonAndWritesNothing() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: [
            "mappings": ["exchange Exchange prompt=prompt"], "tuning": ["reveal: speed 3"], "launch": ["seer = idle"], "directory": folder.path,
        ])
        do {
            _ = try await AnyAgentPackage(ConverseAgent.self).perform(input, host: AgentHost(directory: folder.path))
            XCTFail("the call is refused")
        } catch {
            let text = "\(error)"
            for reason in ["has no colon", "`speed` is not a key of reveal", "`idle` is not a state"] {
                XCTAssertTrue(text.contains(reason), "\(reason) in \(text)")
            }
        }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [])
    }
}
