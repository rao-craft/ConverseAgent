//  WHAT: The launch file, `ConverseLaunch`: the state the stage opens in, read from the `destination` default (the
//        `-destination <name>` launch argument UI tests and screenshots open a screen with), one case a launch line.
//  PIN:  THE KIT OPENS ONLY ITS OWN. A state names the exchanges the stage holds and which of its sheets and pushes
//        are open; the app's navigation opens the tab the stage is on.

import Foundation

enum LaunchEmitter {
    static func emit(_ launches: [(destination: String, state: LaunchState)], prefix: String) -> String {
        let name = prefix + "Launch"
        var lines: [String] = [
            "import Foundation",
            "",
            "/// The state the conversation views open in, read from the `destination` default (the `-destination <name>`",
            "/// launch argument): which exchanges the stage holds, by their place in the app's list, and which of its sheets",
            "/// are open, as if the person had gone there.",
            "enum \(name): Equatable {",
            "    /// The stage with no exchange.",
            "    case empty",
            "    /// The stage holding the exchange at this place, settled.",
            "    case reply(Int)",
            "    /// The transcript over the stage, holding these exchanges.",
            "    case transcript([Int])",
            "    /// The sources of the exchange at this place, over the stage.",
            "    case sources(Int)",
            "    /// A group's documents, by its name or id, pushed in the sources of the exchange at this place.",
            "    case source(Int, String)",
            "    /// The weave over the transcript, holding these exchanges, its entrance done and its first reading open.",
            "    case weave([Int])",
            "",
            "    /// The state for the launch's destination; nil for a destination the call named no state for.",
            "    static var current: \(name)? {",
            "        switch UserDefaults.standard.string(forKey: \"destination\") {",
        ]
        for launch in launches {
            lines.append("        case \(SwiftLiteral.string(launch.destination)): return \(launch.state.swift)")
        }
        lines.append(contentsOf: [
            "        default: return nil",
            "        }",
            "    }",
            "",
            "    /// The exchanges it holds, by their place in the app's list.",
            "    var indices: [Int] {",
            "        switch self {",
            "        case .empty: return []",
            "        case .reply(let index), .sources(let index), .source(let index, _): return [index]",
            "        case .transcript(let indices), .weave(let indices): return indices",
            "        }",
            "    }",
            "",
            "    /// Whether the weave opens over the transcript.",
            "    var opensWeave: Bool {",
            "        if case .weave = self { return true }",
            "        return false",
            "    }",
            "",
            "    /// The group whose documents are pushed in the sources, when it names one.",
            "    var group: String? {",
            "        if case .source(_, let group) = self { return group }",
            "        return nil",
            "    }",
            "}",
        ])
        return lines.joined(separator: "\n") + "\n"
    }
}
