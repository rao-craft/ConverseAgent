//  WHAT: The look file, `ConverseLook`: the fonts and colours the views read, one static member a role, and the
//        palette the strokes are drawn in. A role the call maps reads the app's own name (`Font.brandTitle`); the rest
//        are the system's, so the views build in any app.
//  PIN:  THE APP'S SWIFT IS WRITTEN AS GIVEN. Only the kit's own helper (`ConverseLook.dynamic`) takes the prefix.

import Foundation

enum LookEmitter {
    /// `look`: the call's Swift by role; `palette`: the strokes' colours, in order.
    static func emit(look: [String: String], palette: [TuningColor], prefix: String) -> String {
        let name = prefix + "Look"
        func own(_ swift: String) -> String { swift.replacingOccurrences(of: "ConverseLook.", with: name + ".") }
        var lines: [String] = [
            "import SwiftUI",
            "#if canImport(UIKit)",
            "import UIKit",
            "#elseif canImport(AppKit)",
            "import AppKit",
            "#endif",
            "",
            "/// The fonts and colours the conversation views read, and the palette their strokes are drawn in: the app's own",
            "/// where the call named them, the system's where it did not.",
            "enum \(name) {",
        ]
        for role in LookRole.all {
            let swift = look[role.name].map { WordLines.isColorLiteral($0) ? own($0) : $0 } ?? own(role.fallback)
            lines.append("    /// \(role.doc.prefix(1).uppercased() + role.doc.dropFirst()).")
            lines.append("    static var \(role.name): \(role.isFont ? "Font" : "Color") { \(swift) }")
            lines.append("")
        }
        lines.append("    /// The owners' colours, in order: an owner's tone picks one, and a tone past the last starts again at the first.")
        lines.append("    static let palette: [Color] = [")
        for color in palette { lines.append("        \(color.swift),") }
        lines.append("    ]")
        lines.append(contentsOf: [
            "",
            "    /// The palette's colour for a tone.",
            "    static func tone(_ index: Int) -> Color {",
            "        guard !palette.isEmpty else { return Color.primary }",
            "        return palette[((index % palette.count) + palette.count) % palette.count]",
            "    }",
            "",
            "    /// The system's background: white in light, black in dark.",
            "    static var system: Color {",
            "        #if canImport(UIKit)",
            "        Color(uiColor: .systemBackground)",
            "        #else",
            "        Color(nsColor: .windowBackgroundColor)",
            "        #endif",
            "    }",
            "",
            "    /// One colour in light and another in dark.",
            "    static func dynamic(light: Color, dark: Color) -> Color {",
            "        #if canImport(UIKit)",
            "        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })",
            "        #else",
            "        Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light) })",
            "        #endif",
            "    }",
            "}",
        ])
        return lines.joined(separator: "\n") + "\n"
    }
}
