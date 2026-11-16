import Foundation
import XCTest
@testable import ConverseAgent

/// Every line a call writes, read as a model writes it and refused with a reason that says what the line takes.
final class LineTests: XCTestCase {
    private func refusal(_ body: () throws -> Any) -> String {
        do {
            _ = try body()
            return ""
        } catch {
            return "\(error)"
        }
    }

    // MARK: Mappings

    func testAMappingLineIsReadInEveryFormAModelWrites() throws {
        let line = try MappingLine.parse("exchange: Exchange prompt=prompt, reply = answer ?? \"\" highlights=quotes owners=value.sources")
        XCTAssertEqual(line.role, .exchange)
        XCTAssertEqual(line.type, "Exchange")
        XCTAssertNil(line.id)
        XCTAssertEqual(line.source(of: "prompt"), .path("prompt"))
        XCTAssertEqual(line.source(of: "reply"), .expression("answer ?? \"\""))
        XCTAssertEqual(line.source(of: "owners"), .path("sources"), "a leading value. is the value's own path")

        let owner = try MappingLine.parse("owner: SeerKit.Owner id=slug name=name royalty=stats?.share mine=value.kind == .account")
        XCTAssertEqual(owner.type, "SeerKit.Owner")
        XCTAssertEqual(owner.fileStem, "SeerKitOwner")
        XCTAssertEqual(owner.id, .path("slug"))
        XCTAssertEqual(owner.source(of: "royalty"), .path("stats?.share"))
        XCTAssertEqual(owner.source(of: "mine"), .expression("value.kind == .account"), "`==` never starts a word")

        let highlight = try MappingLine.parse("Highlight: Quote phrase=text owner=source.id")
        XCTAssertEqual(highlight.role, .highlight, "a role in any case")
    }

    func testAMappingLineThatIsNotUnderstoodSaysWhatTheRoleTakes() {
        let cases: [(String, String)] = [
            ("", "it is empty"),
            ("exchange Exchange prompt=prompt", "has no colon"),
            ("turn: Exchange prompt=prompt", "`turn` is not a role: a line starts with exchange, highlight, owner, group, document, reading"),
            ("exchange: ", "it names no type"),
            ("exchange: exchange prompt=prompt", "`exchange` is not a type name"),
            ("exchange: Exchange prompt", "`prompt` is not `word=value`"),
            ("exchange: Exchange title=prompt", "`title` is not something an exchange shows; an exchange maps id, prompt, reply, highlights, owners"),
            ("exchange: Exchange prompt=a prompt=b", "`prompt` is mapped twice"),
            ("owner: Owner id=a id=b", "`id` is mapped twice"),
            ("highlight: Quote id=slug", "`id` is not something a highlight shows"),
            ("exchange: Exchange prompt=", "`prompt` has `=` and no value"),
            ("exchange: Exchange", "it maps nothing"),
        ]
        for (line, reason) in cases {
            let text = refusal { try MappingLine.parse(line) }
            XCTAssertTrue(text.contains(reason), "`\(line)`: \(text)")
        }
    }

    // MARK: Tuning

    func testATuningLineIsReadAsAGroupAKeyOrAColour() throws {
        let reveal = try TuningLine.parse("reveal: base 15, jitter 10, wait 1.2, cursor .55")
        XCTAssertEqual(reveal.map(\.key.name), ["reveal.base", "reveal.jitter", "reveal.wait", "reveal.cursor"])
        XCTAssertEqual(reveal.last?.value, .numbers(["0.55"]), "`.55` is written as Swift reads it")
        XCTAssertEqual(try TuningLine.parse("arrive: curve 0.16, 1, 0.3, 1")[0].value, .numbers(["0.16", "1", "0.3", "1"]))
        XCTAssertEqual(try TuningLine.parse("stroke.opacity = 0.20")[0].value, .numbers(["0.20"]), "a number as written")
        XCTAssertEqual(try TuningLine.parse("leave rise: 30")[0].key.name, "leave.rise")
        XCTAssertEqual(try TuningLine.parse("echoes.weavePadding -2")[0].value, .numbers(["-2"]))
        let orb = try TuningLine.parse("orb: inner rgb(70, 50, 110), opacity 0.045")
        XCTAssertEqual(orb[0].value.colors.first?.swift, "Color(red: 70 / 255, green: 50 / 255, blue: 110 / 255)")
        let palette = try TuningLine.parse("palette = (0.38, 0.55, 0.38) #AE9060")
        XCTAssertEqual(palette[0].value.colors.map(\.swift), ["Color(red: 0.38, green: 0.55, blue: 0.38)", "Color(red: 174 / 255, green: 144 / 255, blue: 96 / 255)"])
    }

    func testATuningLineThatIsNotUnderstoodSaysWhatTheKeyTakes() {
        let cases: [(String, String)] = [
            ("speed: 3", "`speed` is not a tuning group or key"),
            ("reveal: speed 3", "`speed` is not a key of reveal: it takes base, jitter, wait, cursor, cursorOpacity"),
            ("reveal: base fast", "reveal.base takes a number, zero or more"),
            ("leave.rise = -30", "`-30` is below zero"),
            ("arrive.curve = 0.16 1 0.3", "is not 4 numbers"),
            ("pill.lines = 2.5", "is not a whole number"),
            ("orb.inner = (300, 0, 0)", "goes past 255"),
            ("orb.inner = #12", "is not a colour"),
            ("orb.inner = #AE9060 #FFFFFF", "is more than one colour"),
            ("reveal: base 15, base 16", "`reveal.base` is set twice"),
            ("reveal:", "it sets nothing"),
        ]
        for (line, reason) in cases {
            let text = refusal { try TuningLine.parse(line) }
            XCTAssertTrue(text.contains(reason), "`\(line)`: \(text)")
        }
    }

    // MARK: Words, symbols, look

    func testAWordKeepsItsQuotesAndANumberSaysWhereItGoes() throws {
        let words = try WordLines.strings(#"stage.placeholder = " speak into the void...", stage.title = Seer, sources.royalty = "Royalty: {n}%""#)
        XCTAssertEqual(words.map(\.text), [" speak into the void...", "Seer", "Royalty: {n}%"])
        XCTAssertEqual(try WordLines.strings(#"sources.emptyText = No sources, none at all"#)[0].text, "No sources, none at all",
                       "a piece with no `=` goes on the word before it")
        XCTAssertEqual(try WordLines.strings(#"echoes.title = "Say \"hi\"\n""#)[0].text, "Say \"hi\"\n")
        let cases: [(String, String)] = [
            (#"stage.heading = "Seer""#, "`stage.heading` is not a string key"),
            (#"sources.royalty = "Royalty""#, "sources.royalty shows a number: write {n} where it goes"),
            (#"echoes.title = "Echoes {n}""#, "echoes.title shows no number"),
            (#"echoes.title = "Echoes"#, "its quote is never closed"),
            (#"echoes.title = "A", echoes.title = "B""#, "`echoes.title` is set twice"),
        ]
        for (line, reason) in cases {
            let text = refusal { try WordLines.strings(line) }
            XCTAssertTrue(text.contains(reason), "`\(line)`: \(text)")
        }
    }

    func testASymbolIsAnSFSymbolName() throws {
        XCTAssertEqual(try WordLines.symbols("leading = infinity, weave = \"bonjour\"").map(\.name), ["infinity", "bonjour"])
        XCTAssertTrue(refusal { try WordLines.symbols("leading = Infinity Sign") }.contains("is not an SF Symbol name"))
        XCTAssertTrue(refusal { try WordLines.symbols("menu = ellipsis") }.contains("`menu` is not a symbol key"))
    }

    func testALookRoleNamesTheAppsSwiftOrGivesAColour() throws {
        let look = try WordLines.look("title = Font.brandTitle, note = Font.system(size: 17, design: .rounded), accent = #AE9060, card = #FFFFFF / #FFFFFF 0.10, cardShadow = #8E8E8E 0.14 / clear")
        XCTAssertEqual(look.map(\.swift), [
            "Font.brandTitle",
            "Font.system(size: 17, design: .rounded)",
            "Color(red: 174 / 255, green: 144 / 255, blue: 96 / 255)",
            "ConverseLook.dynamic(light: Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255), dark: Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255).opacity(0.10))",
            "ConverseLook.dynamic(light: Color(red: 142 / 255, green: 142 / 255, blue: 142 / 255).opacity(0.14), dark: .clear)",
        ])
        XCTAssertTrue(refusal { try WordLines.look("headline = Font.brandTitle") }.contains("`headline` is not a look role"))
        XCTAssertTrue(refusal { try WordLines.look("title = 24 serif") }.contains("is not Swift for a font"))
        XCTAssertTrue(refusal { try WordLines.look("accent = #AE90 / #FFF") }.contains("accent:"))
    }

    // MARK: Launch and readings

    func testALaunchLineNamesADestinationAndAState() throws {
        let cases: [(String, String, String, String)] = [
            ("seer = empty", "seer", "ConverseLaunch(.empty)", "empty"),
            ("void.reply = reply(0)", "void.reply", "ConverseLaunch(.reply(0))", "reply(0)"),
            ("void.reply: reply", "void.reply", "ConverseLaunch(.reply(0))", "reply(0)"),
            ("echoes = transcript(0)", "echoes", "ConverseLaunch(.transcript([0]))", "transcript(0)"),
            ("echoes = transcript 0 1 2", "echoes", "ConverseLaunch(.transcript([0, 1, 2]))", "transcript(0, 1, 2)"),
            ("echoes.full = transcript(0) large", "echoes.full", "ConverseLaunch(.transcript([0]), large: true)", "transcript(0) large"),
            ("echoes.full = transcript 0 LARGE", "echoes.full", "ConverseLaunch(.transcript([0]), large: true)", "transcript(0) large"),
            ("echoes.half = transcript(0, medium)", "echoes.half", "ConverseLaunch(.transcript([0]))", "transcript(0) medium"),
            ("contributions = sources(3)", "contributions", "ConverseLaunch(.sources(3))", "sources(3)"),
            ("contributions.full = sources large", "contributions.full", "ConverseLaunch(.sources(0), large: true)", "sources(0) large"),
            ("contribution = source(0, \"Orbital Mechanics\")", "contribution", "ConverseLaunch(.source(0, \"Orbital Mechanics\"))", "source(0, \"Orbital Mechanics\")"),
            ("contribution = source \u{201C}Orbital Mechanics\u{201D} large", "contribution", "ConverseLaunch(.source(0, \"Orbital Mechanics\"), large: true)",
             "source(0, \"Orbital Mechanics\") large"),
            ("\"threads\" = weave(0, 1, 2)", "threads", "ConverseLaunch(.weave([0, 1, 2], nil))", "weave(0, 1, 2)"),
            ("threads.full = weave(0, \"outward\") large", "threads.full", "ConverseLaunch(.weave([0], \"outward\"), large: true)", "weave(0, \"outward\") large"),
        ]
        for (line, destination, swift, written) in cases {
            let read = try LaunchLine.parse(line)
            XCTAssertEqual(read.destination, destination, line)
            XCTAssertEqual(read.state.swift(prefix: "Converse"), swift, line)
            XCTAssertEqual(read.state.line, written, line)
        }
    }

    func testALaunchLineThatIsNotUnderstoodSaysTheStates() {
        let cases: [(String, String)] = [
            ("seer", "a launch line is `destination = state`"),
            ("seer view = empty", "is not a destination name"),
            ("seer = idle", "`idle` is not a state: a destination opens empty, reply(i), transcript(i, …), sources(i), source(i, \"group\") or weave(i, …), a height after it (`transcript(0) large`)"),
            ("seer = empty(0)", "empty opens with no exchange"),
            ("seer = empty large", "empty opens no sheet, so it takes no height (`large`)"),
            ("void.reply = reply(0) large", "reply opens no sheet, so it takes no height"),
            ("void.reply = reply(0, 1)", "reply opens one exchange"),
            ("echoes = transcript", "transcript names the exchanges it holds"),
            ("echoes = transcript large", "transcript names the exchanges it holds"),
            ("echoes = transcript(0) full", "`full` is not an exchange's index (0 is the first), a name in quotes or a height (medium, large)"),
            ("echoes = transcript(0) large medium", "it gives two heights"),
            ("echoes = transcript(0, \"outward\")", "transcript takes indices and nothing in quotes"),
            ("threads = weave(0, \"\")", "weave opens a reading by its word, in quotes"),
            ("threads = weave(0, \"outward\", \"here\")", "it names two things in quotes"),
            ("contribution = source(0)", "source names the group it opens, in quotes"),
            ("contribution = source(0, \"Orbital", "its name in quotes is never closed"),
            ("void.reply = reply(-1)", "`-1` is not an exchange's index"),
        ]
        for (line, reason) in cases {
            let text = refusal { try LaunchLine.parse(line) }
            XCTAssertTrue(text.contains(reason), "`\(line)`: \(text)")
        }
    }

    func testAMeasureIsAQualityItsIndicatorsAndItsValueAsWritten() throws {
        let cases: [(String, String, String, String)] = [
            ("DIRECTION = lean · momentum, +0.62", "DIRECTION", "lean · momentum", "+0.62"),
            ("TEXTURE: \"cadence · drift\", \"0.07\"", "TEXTURE", "cadence · drift", "0.07"),
            ("\u{201C}PRESENCE\u{201D} = \u{201C}warmth, depth\u{201D} 0.80", "PRESENCE", "warmth, depth", "0.80"),
            ("Pace = cadence, drift, 0.12", "Pace", "cadence, drift", "0.12"),
            ("DEPTH = reach", "DEPTH", "reach", ""),
        ]
        for (line, quality, indicator, value) in cases {
            let read = try MeasureLine.parse(line)
            XCTAssertEqual(read.quality, quality, line)
            XCTAssertEqual(read.indicator, indicator, line)
            XCTAssertEqual(read.value, value, line)
        }
        XCTAssertTrue(refusal { try MeasureLine.parse("DIRECTION lean · momentum +0.62") }.contains("a measure is `QUALITY = indicators, value`"))
        XCTAssertTrue(refusal { try MeasureLine.parse("= lean, 0.6") }.contains("it names no quality"))
        XCTAssertTrue(refusal { try MeasureLine.parse("DIRECTION = , +0.62") }.contains("`DIRECTION` names no indicators"))
        XCTAssertTrue(refusal { try MeasureLine.parse("DIRECTION = \"lean, 0.6") }.contains("its quote is never closed"))
    }

    func testAReadingIsAWordAndItsReadingWordForWord() throws {
        let read = try ReadingLine.parse("outward: The weft is running ahead of the warp. The arc: above the midline.")
        XCTAssertEqual(read.word, "outward")
        XCTAssertEqual(read.text, "The weft is running ahead of the warp. The arc: above the midline.", "only the first colon cuts")
        XCTAssertEqual(try ReadingLine.parse("\"here\": \"A measured depth.\"").text, "A measured depth.")
        XCTAssertTrue(refusal { try ReadingLine.parse("outward") }.contains("a reading is `word: the reading`"))
        XCTAssertTrue(refusal { try ReadingLine.parse(": a reading") }.contains("it names no word"))
        XCTAssertTrue(refusal { try ReadingLine.parse("outward:") }.contains("`outward` has no reading"))
    }

    // MARK: The whole call

    func testACallIsRefusedWithEveryReasonAtOnceAndWritesNothing() throws {
        let folder = try Fixture.folder()
        let problems = Fixture.problems(.init(
            prefix: "void", imports: ["Seer Kit"], mappings: ["exchange: Exchange prompt=prompt", "exchange: Exchange reply=reply", "turn: Turn"],
            look: ["headline = Font.brandTitle"], strings: ["stage.heading = \"Seer\""], symbols: ["menu = ellipsis"],
            tuning: ["reveal: speed 3", "stroke.top = 0.10 -0.25", "pill.lines = 0"],
            launch: ["seer = empty", "seer = reply(0)", "threads = weave(0, \"there\")"], readings: ["here: a", "here: b"],
            measures: ["DIRECTION = lean, 0.6", "DIRECTION = drift, 0.1", "TEXTURE"], directory: folder.path))
        let expected = [
            "mappings: `turn: Turn`: `turn` is not a role",
            "mappings: `Exchange` is mapped as exchange twice",
            "tuning: `reveal: speed 3`",
            "strings: `stage.heading = \"Seer\"`",
            "symbols: `menu = ellipsis`",
            "look: `headline = Font.brandTitle`",
            "launch: `seer` is given two states",
            "launch: `threads = weave(0, \"there\")`: `there` is not a reading's word: the readings are here",
            "readings: `here` is given twice",
            "measures: `DIRECTION` is given twice",
            "measures: `TEXTURE`: a measure is `QUALITY = indicators, value`",
            "tuning: stroke.top moves a stroke's points between its two numbers, the lower first",
            "tuning: pill.lines is how many lines the field grows to, at least 1",
            "prefix: `void` is not a word type names can start with",
            "imports: `Seer Kit` is not a module name",
        ]
        for reason in expected {
            XCTAssertTrue(problems.contains { $0.hasPrefix(reason) }, "\(reason) in\n\(problems.joined(separator: "\n"))")
        }
        XCTAssertEqual(problems.count, expected.count, problems.joined(separator: "\n"))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: folder.path), [], "nothing was written")
    }

    func testTheSameKeyInTwoLinesIsRefused() {
        let problems = Fixture.problems(.init(look: ["accent = Color.red", "accent = Color.blue"], strings: ["echoes.title = \"A\"", "echoes.title = \"B\""],
                                              symbols: ["send = arrow.up", "send = paperplane"], tuning: ["reveal: base 15", "reveal.base = 16"]))
        XCTAssertEqual(Set(problems), ["strings: `echoes.title` is set twice", "symbols: `send` is set twice", "tuning: `reveal.base` is set twice",
                                       "look: `accent` is set twice"])
    }
}
