//  WHAT: The readings file, `ConverseReadings`: the weave's words and the reading each opens, word for word as the
//        call gave them. The stage shows these when the page passes no readings of its own; with none, the
//        transcript draws no weave button.

import Foundation

enum ReadingsEmitter {
    static func emit(_ readings: [(word: String, text: String)], prefix: String) -> String {
        let name = prefix + "Readings"
        let value = prefix + "Reading"
        var lines: [String] = [
            "import Foundation",
            "",
            "/// The weave's words and the reading each opens, as the call gave them.",
            "enum \(name) {",
        ]
        if readings.isEmpty {
            lines.append("    static let all: [\(value)] = []")
        } else {
            lines.append("    static let all: [\(value)] = [")
            for reading in readings {
                lines.append("        \(value)(")
                lines.append("            word: \(SwiftLiteral.string(reading.word)),")
                lines.append("            text: \(SwiftLiteral.string(reading.text))")
                lines.append("        ),")
            }
            lines.append("    ]")
        }
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }
}
