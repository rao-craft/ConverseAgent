import Foundation
@testable import ConverseAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("converse-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The package's own folder, where `Schema/` is.
    static var package: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    /// An example call from `Schema/examples/`, as a host sends it.
    static func example(_ name: String) throws -> ConverseAgent.Input {
        let data = try Data(contentsOf: package.appendingPathComponent("Schema/examples/\(name).json"))
        return try JSONDecoder().decode(ConverseAgent.Input.self, from: data)
    }

    /// The Seer call, written into `folder`.
    static func seer(into folder: URL) throws -> ConverseResult {
        var input = try example("seer")
        input.directory = folder.path
        return try ConverseAgent.write(input, note: { _ in }, yield: { _ in })
    }

    /// The text of the file `name` among `paths`.
    static func text(_ paths: [String], _ name: String) throws -> String {
        guard let path = paths.first(where: { $0.hasSuffix("/" + name) }) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: name])
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Every file among `paths`, joined: what a regex over the app's Swift reads.
    static func all(_ paths: [String]) throws -> String {
        try paths.sorted().map { try String(contentsOfFile: $0, encoding: .utf8) }.joined(separator: "\n")
    }

    /// A file the repository ships, read, beside the object it should hold; `CONVERSE_EXAMPLES=1` writes the object
    /// there first, as JSON a person reads (sorted keys, two spaces).
    static func shipped(_ object: Any, at path: String) throws -> (shipped: NSDictionary?, made: NSDictionary?) {
        let url = package.appendingPathComponent(path)
        if ProcessInfo.processInfo.environment["CONVERSE_EXAMPLES"] == "1" {
            let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try (String(decoding: pretty, as: UTF8.self) + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
        let shipped = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        return (shipped as? NSDictionary, object as? NSDictionary)
    }

    /// `text` written at `url`, its folders made.
    static func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    /// The problems a refused call names; empty when it was not refused.
    static func problems(_ input: ConverseAgent.Input) -> [String] {
        var call = input
        if call.directory == nil { call.directory = try? folder().path }
        do {
            _ = try ConverseAgent.write(call, note: { _ in }, yield: { _ in })
            return []
        } catch ConverseError.problems(let reasons) {
            return reasons
        } catch {
            return ["\(error)"]
        }
    }
}
