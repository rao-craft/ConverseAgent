//  WHAT: The readings file, `ConverseReadings`: the weave's words and the reading each opens, and the measures its
//        legend lists under the rows, word for word as the call gave them. The stage shows these readings when the
//        page passes none of its own; with none, the transcript draws no weave button. With no measures, the weave
//        draws no legend.

import Foundation

enum ReadingsEmitter {
    static func emit(_ readings: [(word: String, text: String)], measures: [(quality: String, indicator: String, value: String)],
                     prefix: String) -> String {
        let name = prefix + "Readings"
        let value = prefix + "Reading"
        let measure = prefix + "Measure"
        var lines: [String] = [
            "import Foundation",
            "",
            "/// The weave's words and the reading each opens, and the measures its legend lists, as the call gave them.",
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
        lines.append("")
        if measures.isEmpty {
            lines.append("    static let measures: [\(measure)] = []")
        } else {
            lines.append("    static let measures: [\(measure)] = [")
            for item in measures {
                lines.append("        \(measure)(quality: \(SwiftLiteral.string(item.quality)), indicator: \(SwiftLiteral.string(item.indicator)), value: \(SwiftLiteral.string(item.value))),")
            }
            lines.append("    ]")
        }
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }
}
