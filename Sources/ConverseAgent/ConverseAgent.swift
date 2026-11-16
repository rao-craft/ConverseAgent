//  WHAT: A conversation's screens as a Granite agent package. A call names the app's types with one mapping line a
//        role (`exchange: Exchange prompt=prompt reply=reply highlights=highlights owners=owners`), and its words,
//        numbers, symbols, look, launch states, the weave's readings and its legend's measures with lines of their
//        own; the run writes plain SwiftUI into the folder the call names (the stage that types a reply out and brushes
//        its sources' phrases, the transcript, the sources and a group's documents, the woven reading), the
//        conformances that make the app's types the views' values, and answers where.
//  IN:   Input: the folder, a prefix, the modules a mapped type lives in, and the lines.
//  OUT:  ConverseResult: the files written, the views, the conformances, the root views' initializers, the launch
//        states, and what the app still has to do.
//  PIN:  NO MODEL. Every file is made from the call, the same way every time; a line that is not understood is
//        refused with its reason, every reason at once, and nothing is written until every file parses.
//  PIN:  THE VIEWS NEVER ROUTE PAST THEIR OWN SHEETS. The stage takes values and closures (`send`, `load`, `leading`)
//        and presents only the transcript, the sources and the weave; the app's tabs and sheets stay the app's.

import Foundation
import GraniteAgents

public struct ConverseAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The folder the views go in, relative to the project; `Components/Converse` when left out.
        public var into: String?
        /// The word every type the kit writes starts with in place of `Converse`: `Void` writes `VoidStage`.
        public var prefix: String?
        /// Modules the conformances import: where a mapped type lives.
        public var imports: [String]?
        /// One line a role: `exchange: Exchange prompt=prompt reply=reply highlights=highlights owners=owners`.
        public var mappings: [String]?
        /// Fonts and colours by role: `title = Font.brandTitle, accent = Color.accent, card = #FFFFFF / #FFFFFF 0.10`.
        public var look: [String]?
        /// Words by key: `stage.title = "Seer", sources.royalty = "Royalty: {n}%"`.
        public var strings: [String]?
        /// SF Symbols by key: `leading = infinity, weave = bonjour`.
        public var symbols: [String]?
        /// Numbers by group or key: `reveal: base 15, jitter 10, wait 1.2`, `stroke.opacity = 0.20`.
        public var tuning: [String]?
        /// One line a destination: `void.reply = reply(0)`, `contribution = source(0, "Orbital Mechanics")`.
        public var launch: [String]?
        /// One line a word of the weave: `outward: The weft is running ahead of the warp.`
        public var readings: [String]?
        /// One line a measure the weave's legend lists under its rows: `DIRECTION = lean · momentum, +0.62`.
        public var measures: [String]?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, prefix: String? = nil, imports: [String]? = nil, mappings: [String]? = nil,
                    look: [String]? = nil, strings: [String]? = nil, symbols: [String]? = nil, tuning: [String]? = nil,
                    launch: [String]? = nil, readings: [String]? = nil, measures: [String]? = nil, directory: String? = nil) {
            self.into = into; self.prefix = prefix; self.imports = imports; self.mappings = mappings; self.look = look
            self.strings = strings; self.symbols = symbols; self.tuning = tuning; self.launch = launch
            self.readings = readings; self.measures = measures; self.directory = directory
        }
    }

    public typealias Event = ConverseFrame
    public typealias Output = ConverseResult
    public typealias Compute = Void

    public static let word = "converse"
    /// What it makes: the views a page shows, and the conformances that make the app's types their values.
    public static let makes = [
        AgentMake(kind: "view", what: "a conversation's screens as reusable SwiftUI views: ConverseStage (one exchange at a time, the reply typed out and brushed, a glass input), and the sheets it opens itself (ConverseTranscript, ConverseSources with ConverseSourceDetail, ConverseWeave); a page shows ConverseStage(exchanges:send:)",
                  into: ["Components/Converse/*"], never: "routes past its own sheets; never a page, a service, a client or a model type"),
        AgentMake(kind: "conformance", what: "the app's own types made the views' values: one extension a mapping line",
                  into: ["Components/Converse/Conformances/*"], never: "a change to the app's types themselves"),
    ]
    public static let summary = "writes a conversation's screens as plain SwiftUI (a stage that types each reply out and brushes the phrases its sources gave, a glass input, the transcript, whose documents shaped a reply with their royalties, and a woven reading), made to show the app's own types from one mapping line a type."
    public static let fields = [
        "into": "the folder for the views, relative to the project; Components/Converse when left out",
        "prefix": "the word the kit's types start with in place of Converse, when the app already has those names: Void writes VoidStage",
        "imports": "modules the conformances import, such as the package a mapped type is declared in",
        "mappings": "one line a role (exchange, highlight, owner, group, document, reading): `exchange: Exchange prompt=prompt reply=reply highlights=highlights owners=owners`; a bare path is read off the value, anything else is Swift that may name `value`",
        "look": "fonts and colours by role, several to a line: `title = Font.brandTitle, body = Font.brandBody, accent = Color.accent, card = #FFFFFF / #FFFFFF 0.10`; roles: title, body, body2, note, note2, accent, background, card, cardShadow, buttonShadow",
        "strings": "words by key, several to a line: `stage.title = \"Seer\", sources.royalty = \"Royalty: {n}%\"`; a word in quotes keeps its spaces",
        "symbols": "SF Symbols by key: `leading = infinity, weave = bonjour`",
        "tuning": "numbers by group or key: `reveal: base 15, jitter 10, wait 1.2`, `stroke.opacity = 0.20`, `palette = (0.38, 0.55, 0.38) (0.56, 0.49, 0.32)`",
        "launch": "one line a destination and the state the stage opens in: empty, reply(i), transcript(i, …), sources(i), source(i, \"group\") or weave(i, …), a reading's word in quotes opening it (`weave(0, \"outward\")`), and `large` after a state that opens a sheet for its full height: `contribution = source(0, \"Orbital Mechanics\")`, `echoes.full = transcript(0) large`",
        "readings": "one line a word of the weave and the reading it opens: `outward: The weft is running ahead of the warp.`",
        "measures": "one line a measure the weave's legend lists under its rows, in order: the quality, the indicators it is read from and its value, `DIRECTION = lean · momentum, +0.62`; no legend without them",
    ]
    public static let guide = """
        Tag converse for a conversation with a model: a stage that shows one exchange at a time (the prompt, the \
        reply typed out with a cursor, thinking dots while it waits, the last exchange rising away as the next \
        arrives, phrases of the reply brushed in their owner's colour), a slow orb behind, a Liquid Glass input \
        pinned to the bottom; the transcript as a sheet; whose documents shaped a reply and the royalty each earned, \
        with a group's documents pushed; and the weave, an animated canvas over words that open readings. It writes \
        plain SwiftUI (iOS 17 and macOS 14, Liquid Glass on iOS 26) into `into` (Components/Converse). A page shows \
        `ConverseStage(exchanges: chat.state.exchanges, send: { try await chat.send(text: $0) })`: `exchanges` \
        oldest first, `send` adds one (its reply may come later); optional `load` (fetches the conversation a launch \
        needs), `leading` (the bar's leading button), `listen` (a microphone in the input), `documents` (the app's \
        view of documents by id). The stage opens its own sheets; the app's tabs, sheets and services stay the app's. \
        `mappings` make the app's types the views' values, one line a role: exchange (id, prompt, reply, highlights, \
        owners); highlight (phrase, owner: the owner's id or name); owner (id, name, royalty, mine, tone, documents, \
        groups); group (id, name, summary, tags, documents); document (id, text, influence); reading (word, text). \
        A bare path is read off the value (`owner=ownerId`); anything else is Swift that may name `value`. A royalty \
        or influence may be a whole percent or a share of 1; a list needs its element's own line. Say `id=` only when \
        the type has no `id`; a type from a package needs `imports`. `look` maps fonts and colours to the app's names \
        (`title = Font.brandTitle, accent = Color.accent`) or gives colours (`#AE9060`, `#FFFFFF / #1C1C1E` for light \
        and dark, an opacity after one: `#8E8E8E 0.14 / clear`); a role left out is the system's. `strings` set the \
        words (stage.title, stage.placeholder, stage.echoesLabel, echoes.title, echoes.copy, close, sources.title, \
        sources.library, sources.royalty, sources.influence, sources.docs, sources.doc, sources.emptyTitle, \
        sources.emptyText, detail.title, weave.title and more); `symbols` the SF Symbols (leading, echoes, close, \
        keyboard, send, weave, copy, document, person, empty); `tuning` every number (reveal, leave, arrive, stroke, \
        palette, orb, idle, dots, stage, column, ink, pill, edge, echoes, sources, detail, weave, legend groups). `launch` \
        maps a `-destination` name to the state the stage opens in: empty, reply(i), transcript(i, …), sources(i), \
        source(i, "group"), weave(i, …) (`weave(0, "outward")` opens that reading), an index being an exchange's \
        place in the app's list; `large` after a state opens its sheets at full height (`echoes.full = transcript(0) \
        large`), medium otherwise; the app's navigation opens the stage's tab for each name. `readings` give the \
        weave's words: `word: reading`; `measures` the legend under its rows, one line each, `QUALITY = indicators, \
        value` (`DIRECTION = lean · momentum, +0.62`). Example, a tutoring \
        app: {"mappings": ["exchange: Turn prompt=question reply=answer highlights=quotes owners=sources", \
        "highlight: Quote phrase=text owner=sourceID", "owner: Source name=title royalty=share documents=pages", \
        "document: Page text=body influence=weight"], "strings": ["stage.title = \\"Tutor\\", sources.title = \
        \\"Sources\\""], "symbols": ["leading = book"], "launch": ["tutor = empty", "tutor.answer = reply(0)"], \
        "readings": ["curious: The questions keep reaching past the lesson."]}. A line it cannot read is refused \
        with the reason and nothing is written: fix the line and call again. Not for the app's services, its \
        network client or its model types.
        """

    public static func output(from events: [ConverseFrame]) -> ConverseResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<ConverseFrame, Error> {
        // The folder is the call's, else the host's (a host over the wire may give it only there), else the
        // process's: never the runner's working folder while the host named one.
        var resolved = input
        if resolved.directory == nil { resolved.directory = context.host.directory }
        let call = resolved
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The call's lines, read: every value the templates take, and every problem at once.
    struct Read {
        var mappings: [Mapping] = []
        var values = KitValues.defaults
        var look: [String: String] = [:]
        var launches: [(destination: String, state: LaunchState)] = []
        var readings: [(word: String, text: String)] = []
        var measures: [(quality: String, indicator: String, value: String)] = []
        var problems: [String] = []
    }

    static func read(_ input: Input) -> Read {
        var read = Read()
        func lines(_ list: [String]?) -> [String] {
            (list ?? []).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        func refuse(_ field: String, _ error: Error) { read.problems.append("\(field): \(error)") }

        for line in lines(input.mappings) {
            do { read.mappings.append(try MappingLine.parse(line)) } catch { refuse("mappings", error) }
        }
        var mapped: Set<String> = []
        for mapping in read.mappings where !mapped.insert("\(mapping.role.rawValue) \(mapping.type)").inserted {
            read.problems.append("mappings: `\(mapping.type)` is mapped as \(mapping.role.rawValue) twice: one line a type and role")
        }

        var tuned: Set<String> = []
        for line in lines(input.tuning) {
            do {
                for (key, value) in try TuningLine.parse(line) {
                    if !tuned.insert(key.name).inserted { read.problems.append("tuning: `\(key.name)` is set twice") }
                    read.values.tuning[key.name] = value
                }
            } catch { refuse("tuning", error) }
        }
        var worded: Set<String> = []
        for line in lines(input.strings) {
            do {
                for (key, text) in try WordLines.strings(line) {
                    if !worded.insert(key.name).inserted { read.problems.append("strings: `\(key.name)` is set twice") }
                    read.values.strings[key.name] = text
                }
            } catch { refuse("strings", error) }
        }
        var drawn: Set<String> = []
        for line in lines(input.symbols) {
            do {
                for (key, name) in try WordLines.symbols(line) {
                    if !drawn.insert(key.name).inserted { read.problems.append("symbols: `\(key.name)` is set twice") }
                    read.values.symbols[key.name] = name
                }
            } catch { refuse("symbols", error) }
        }
        for line in lines(input.look) {
            do {
                for (role, swift) in try WordLines.look(line) {
                    if read.look[role.name] != nil { read.problems.append("look: `\(role.name)` is set twice") }
                    read.look[role.name] = swift
                }
            } catch { refuse("look", error) }
        }
        for line in lines(input.launch) {
            do {
                let launch = try LaunchLine.parse(line)
                if read.launches.contains(where: { $0.destination == launch.destination }) {
                    read.problems.append("launch: `\(launch.destination)` is given two states: one line a destination")
                } else {
                    read.launches.append(launch)
                }
            } catch { refuse("launch", error) }
        }
        for line in lines(input.readings) {
            do {
                let reading = try ReadingLine.parse(line)
                if read.readings.contains(where: { $0.word == reading.word }) {
                    read.problems.append("readings: `\(reading.word)` is given twice: one line a word")
                } else {
                    read.readings.append(reading)
                }
            } catch { refuse("readings", error) }
        }
        for line in lines(input.measures) {
            do {
                let measure = try MeasureLine.parse(line)
                if read.measures.contains(where: { $0.quality == measure.quality }) {
                    read.problems.append("measures: `\(measure.quality)` is given twice: one line a measure")
                } else {
                    read.measures.append(measure)
                }
            } catch { refuse("measures", error) }
        }
        let words = read.readings.map(\.word)
        for launch in read.launches where launch.state.name == .weave && !words.isEmpty {
            if let word = launch.state.quoted, !words.contains(word) {
                read.problems.append("launch: `\(launch.destination) = \(launch.state.line)`: `\(word)` is not a reading's word: the readings are \(words.joined(separator: ", "))")
            }
        }

        // Numbers that are ranges, where a reversed one would stop the app when it draws.
        func numbers(_ key: String) -> [Double] { read.values.tuning[key]?.numbers.compactMap(Double.init) ?? [] }
        for key in ["stroke.top", "stroke.bottom"] {
            let range = numbers(key)
            if range.count == 2, range[0] > range[1] {
                read.problems.append("tuning: \(key) moves a stroke's points between its two numbers, the lower first, like `\(key) = \(range[1]) \(range[0])`")
            }
        }
        if let lines = numbers("pill.lines").first, lines < 1 {
            read.problems.append("tuning: pill.lines is how many lines the field grows to, at least 1, like `pill.lines = 5`")
        }
        return read
    }

    /// The whole call: the lines read and checked against the app's types, the kit made, staged, parsed and written.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (ConverseFrame) -> Void) throws -> ConverseResult {
        var call = read(input)
        var problems = call.problems
        var notes: [String] = []
        let files = AgentFiles(directory: input.directory)
        let into = (input.into ?? "").trimmingCharacters(in: .whitespaces)
        let folder = files.resolve(into.isEmpty ? "Components/Converse" : into)

        let named = (input.prefix ?? "").trimmingCharacters(in: .whitespaces)
        if !named.isEmpty, !SwiftName.isTypeName(named) {
            problems.append("prefix: `\(named)` is not a word type names can start with: UpperCamelCase letters and digits, like `Void`")
        }
        let held = KitOnDisk.prefix(in: folder)
        if !named.isEmpty, let held, held != named {
            problems.append("prefix: \(files.relative(folder)) already holds the kit named `\(held)`: leave `prefix` out to write it again, or write into another folder")
        }
        let prefix = named.isEmpty ? (held ?? "Converse") : named

        var imports: [String] = []
        for module in (input.imports ?? []).map({ $0.trimmingCharacters(in: .whitespaces) }) where !module.isEmpty && !imports.contains(module) {
            if SwiftName.isModuleName(module) { imports.append(module) } else { problems.append("imports: `\(module)` is not a module name") }
        }

        // Each path checked against the app's own types, in their spelling; a type a local package declares imported.
        // The kit's own folder is not the app's: its previews declare values of the kit's own.
        let app = AppTypes(root: files.root, excluding: folder)
        // The module the kit's folder compiles into, when a local package holds it: a type declared there is never imported.
        let home = AppTypes.module(of: folder.appendingPathComponent(prefix + "Stage.swift"))
        var mappedAs: [ConverseRole: Set<String>] = [:]
        for mapping in call.mappings { mappedAs[mapping.role, default: []].insert(AppTypes.named(mapping.type)) }
        call.mappings = call.mappings.map { mapping in
            guard let declared = app.types[AppTypes.named(mapping.type)] else { return mapping }
            if let module = declared.module, module != home, !imports.contains(module), !mapping.type.hasPrefix(module + ".") {
                imports.append(module)
                notes.append("`\(mapping.type)` is declared in \(module), so the conformances import it.")
            }
            let line = mapping.line.trimmingCharacters(in: .whitespacesAndNewlines)
            if mapping.role.identified, mapping.id == nil, declared.field("id") == nil {
                let example = declared.fields.first { $0.type.hasPrefix("String") }?.name ?? declared.fields.first?.name ?? "name"
                problems.append("mappings: `\(line)`: `\(declared.name)` has no `id`: say which field tells one from another, like `id=\(example)`")
            }
            func checked(_ source: Mapping.Source, _ word: String, kind: ConverseKind) -> Mapping.Source {
                guard case .path(let path) = source else { return source }
                let (fixed, problem) = app.check(path, from: mapping.type)
                if let problem {
                    problems.append("mappings: `\(line)`: \(word)=\(path): \(problem)")
                    return source
                }
                if let written = app.type(of: fixed, from: mapping.type), let reason = Self.mismatch(written, kind: kind, app: app, mappedAs: mappedAs, prefix: prefix) {
                    problems.append("mappings: `\(line)`: \(word)=\(path): `\(fixed)` is `\(written)`, and \(reason)")
                    return source
                }
                if fixed != path { notes.append("\(mapping.role.rawValue) \(word): `\(path)` is `\(fixed)` on \(declared.name).") }
                return .path(fixed)
            }
            return Mapping(line: mapping.line, role: mapping.role, type: mapping.type,
                           id: mapping.id.map { checked($0, "id", kind: .text) },
                           assignments: mapping.assignments.map { Mapping.Assignment(property: $0.property, source: checked($0.source, $0.property.key, kind: $0.property.kind)) })
        }
        guard problems.isEmpty else { throw ConverseError.problems(problems) }

        // The files: every template part, the look, the launch, the readings, and one conformance a mapping line.
        let values = call.values
        let title = values.strings["stage.title"] ?? ""
        let flags: Set<String> = title.isEmpty ? [] : ["title"]
        var planned: [(url: URL, text: String)] = []
        for part in KitCatalog.parts {
            let rendered = try TemplateRender.render(part.template, flags: flags)
            let text = try TemplateFill.fill(TemplateRender.renaming(rendered, prefix: prefix), with: values)
            planned.append((folder.appendingPathComponent(prefix + part.name + ".swift"), text))
        }
        planned.append((folder.appendingPathComponent(prefix + "Look.swift"),
                        LookEmitter.emit(look: call.look, palette: values.tuning["palette"]?.colors ?? [], prefix: prefix)))
        planned.append((folder.appendingPathComponent(prefix + "Launch.swift"), LaunchEmitter.emit(call.launches, prefix: prefix)))
        planned.append((folder.appendingPathComponent(prefix + "Readings.swift"), ReadingsEmitter.emit(call.readings, measures: call.measures, prefix: prefix)))
        let conformances = folder.appendingPathComponent("Conformances", isDirectory: true)
        for mapping in call.mappings {
            let file = ConformanceEmitter.emit(mapping, imports: imports, prefix: prefix)
            planned.append((conformances.appendingPathComponent(file.name), file.text))
        }
        yield(.read(mappings: call.mappings.count, files: planned.count))
        note("writing \(planned.count) files into \(files.relative(folder))")

        let existed = Set(planned.map(\.url.path).filter { FileManager.default.fileExists(atPath: $0) })
        let unchanged = Set(planned.filter { (try? String(contentsOf: $0.url, encoding: .utf8)) == $0.text }.map(\.url.path))
        let written = try files.write(planned)
        note("wrote \(written.count) files")

        func state(_ path: String) -> AgentMade.State {
            unchanged.contains(path) ? .unchanged : existed.contains(path) ? .rewritten : .written
        }
        func file(_ name: String) -> String? { written.first { ($0 as NSString).lastPathComponent == name } }
        var made: [AgentMade] = KitCatalog.parts.compactMap { part in
            guard let view = part.views.first, let path = file(prefix + part.name + ".swift") else { return nil }
            return AgentMade(kind: "view", name: prefix + view, path: path, state: state(path))
        }
        made += call.mappings.compactMap { mapping in
            file(ConformanceEmitter.fileName(mapping, prefix: prefix)).map { AgentMade(kind: "conformance", name: mapping.type, path: $0, state: state($0)) }
        }
        let expected = KitCatalog.roots.map { AgentExpected(kind: "view", name: prefix + $0) }
            + call.mappings.map { AgentExpected(kind: "conformance", name: $0.type) }

        notes += Self.notes(call, prefix: prefix, title: title)
        if held != nil {
            notes.append("\(files.relative(folder)) held the kit already: every file was written again from this call, so keep the app's changes in its own files.")
        }
        return ConverseResult(path: written.first, paths: written, views: KitCatalog.views.map { prefix + $0 },
                              conformances: call.mappings.map { "\($0.type): \($0.role.rawValue)" },
                              initializers: Self.initializers(call, prefix: prefix),
                              launch: call.launches.map { "\($0.destination) = \($0.state.line)" },
                              notes: notes, made: made, expected: expected)
    }

    /// Why a field of type `written` cannot show as `kind`, or nil when it can (or the type is one this reader does
    /// not know, which is taken as written).
    static func mismatch(_ written: String, kind: ConverseKind, app: AppTypes, mappedAs: [ConverseRole: Set<String>], prefix: String) -> String? {
        var base = written
        while base.hasSuffix("?") || base.hasSuffix("!") { base.removeLast() }
        let isList = base.hasPrefix("[") && !base.contains(":") || base.hasPrefix("Array<")
        let integers: Set<String> = ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]
        let known = integers.union(["String", "Substring", "URL", "UUID", "Double", "Float", "CGFloat", "Decimal", "Bool", "Date"])
        if case .list(let role) = kind {
            let element = AppTypes.named(base)
            guard isList, !known.contains(element) else { return "`\(role.plural)` shows a list of values \(role.article) `\(role.rawValue):` line maps" }
            if element == role.valueType(prefix) || mappedAs[role]?.contains(element) == true { return nil }
            guard app.types[element] != nil else { return nil }
            return "each `\(element)` needs a line of its own: add `\(role.rawValue): \(element) \(role.properties[0].key)=…`"
        }
        if kind.takes.contains(base) || kind.takes.contains(written) { return nil }
        let declaredHere = app.types[AppTypes.named(base)] != nil && !isList
        guard declaredHere || known.contains(base) || isList else { return nil }
        return "it shows \(kind.inWords): map a field of one of those, or write Swift that makes one"
    }

    /// Each root view's initializer, as a page calls it.
    static func initializers(_ call: Read, prefix: String) -> [String] {
        let exchange = call.mappings.first { $0.role == .exchange }?.type ?? "\(prefix)Exchange"
        return [
            "\(prefix)Stage(exchanges: [\(exchange)], readings: [any \(prefix)ReadingRepresentable] = \(prefix)Readings.all, send: @MainActor (String) async throws -> Void, load: (@MainActor () async throws -> Void)? = nil, leading: (@MainActor () -> Void)? = nil, leadingActive: Bool = false, listen: (@MainActor () -> Void)? = nil, listening: Bool = false, documents: (([String]) -> some View)? = nil)",
            "\(prefix)Transcript(exchanges: [\(prefix)Exchange], readings: [\(prefix)Reading], opensWeave: Bool = false, weaveLarge: Bool = false, weaveReading: String? = nil)",
            "\(prefix)Sources(exchange: \(prefix)Exchange?, opening: String? = nil)",
            "\(prefix)SourceDetail(documents: [\(prefix)Document], close: () -> Void)",
            "\(prefix)Weave(readings: [\(prefix)Reading], measures: [\(prefix)Measure] = \(prefix)Readings.measures, entered: Bool = false, open: String? = nil)",
        ]
    }

    /// What the app still has to do, one sentence each.
    static func notes(_ call: Read, prefix: String, title: String) -> [String] {
        var notes: [String] = []
        let exchange = call.mappings.first { $0.role == .exchange }
        notes.append("A page shows the stage as the root of its navigation stack: \(prefix)Stage(exchanges: \(exchange == nil ? "exchanges" : "chat.state.exchanges"), send: { try await chat.send(text: $0) }); it opens the transcript, the sources and the weave itself, and puts its buttons\(title.isEmpty ? "" : " and its title, inline,") in the stack's bar: the page keeps that bar shown and sets no title display mode of its own.")
        if exchange == nil {
            notes.append("No line maps an exchange: pass [\(prefix)Exchange] values, or add `exchange: Type prompt=… reply=… highlights=… owners=…`.")
        }
        if !call.launches.isEmpty {
            let names = call.launches.map(\.destination).joined(separator: ", ")
            notes.append("The app's navigation opens the stage's page for \(names); the stage opens its own sheets and pushes for each, and calls `load` when the list does not hold the exchanges a state names yet.")
        }
        if call.readings.isEmpty {
            notes.append("No readings were given, so the transcript draws no weave button: add `readings` lines, or pass `readings:` to the stage.")
        }
        let unmapped = LookRole.all.filter { call.look[$0.name] == nil }.map(\.name)
        if !unmapped.isEmpty {
            notes.append("The look uses the system's \(unmapped.joined(separator: ", ")): map the app's own with `look` lines.")
        }
        if title.isEmpty { notes.append("stage.title is empty, so the stage's bar shows no title.") }
        return notes
    }
}
