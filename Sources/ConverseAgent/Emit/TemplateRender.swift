//  WHAT: A template made into the app's file: the blocks a call did not ask for dropped, the kit's types renamed
//        with the call's prefix. Its conditions are comment lines:
//
//            //@if title                   a flag the call sets: `title` when the stage has one
//            //@else
//            //@endif
//
//  PIN:  A MARKER IS A LINE OF ITS OWN and never reaches the app. An unbalanced block is a fault of the template,
//        caught by the tests before any call is made. The kit's names take the call's prefix by `renaming`, before
//        the call's words are filled in, so a word that says `Converse` is never renamed.

import Foundation

enum TemplateRender {
    enum Failure: Error, Equatable { case unbalanced(String) }

    /// `source` with every block whose condition is false dropped, and the marker lines gone.
    static func render(_ source: String, flags: Set<String>) throws -> String {
        var output: [Substring] = []
        // Each open block: whether its branch is kept, and whether the block as a whole sits in a kept branch.
        var stack: [(keeping: Bool, parent: Bool)] = []
        var keeping = true
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//@if ") {
                let condition = holds(String(trimmed.dropFirst(6)), flags: flags)
                stack.append((keeping && condition, keeping))
                keeping = keeping && condition
            } else if trimmed == "//@else" {
                guard let top = stack.popLast() else { throw Failure.unbalanced("//@else without //@if") }
                stack.append((top.parent && !top.keeping, top.parent))
                keeping = top.parent && !top.keeping
            } else if trimmed == "//@endif" {
                guard let top = stack.popLast() else { throw Failure.unbalanced("//@endif without //@if") }
                keeping = top.parent
            } else if keeping {
                output.append(line)
            }
        }
        guard stack.isEmpty else { throw Failure.unbalanced("\(stack.count) //@if without //@endif") }
        return tidy(output.map(String.init))
    }

    /// The lines as a file: no trailing spaces, no run of blank lines and no blank line against a brace (where a
    /// dropped block leaves them), one newline at the end.
    static func tidy(_ lines: [String]) -> String {
        var kept: [String] = []
        for (index, raw) in lines.enumerated() {
            var line = raw
            while line.last == " " || line.last == "\t" { line.removeLast() }
            if line.isEmpty {
                let next = lines[(index + 1)...].first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                let afterOpening = kept.last.map { $0.hasSuffix("{") } ?? true
                let beforeClosing = next.map { $0.trimmingCharacters(in: .whitespaces).hasPrefix("}") } ?? true
                if kept.last?.isEmpty == true || afterOpening || beforeClosing { continue }
            }
            kept.append(line)
        }
        return kept.joined(separator: "\n") + "\n"
    }

    /// `a || b && !c`: `&&` binds tighter than `||`; a name holds when it is in `flags`.
    static func holds(_ condition: String, flags: Set<String>) -> Bool {
        condition.components(separatedBy: "||").contains { any in
            any.components(separatedBy: "&&").allSatisfy { term in
                let word = term.trimmingCharacters(in: .whitespaces)
                return word.hasPrefix("!") ? !flags.contains(String(word.dropFirst())) : flags.contains(word)
            }
        }
    }

    /// `text` with the kit's own names given the call's prefix in place of `Converse`: `ConverseStage` is
    /// `VoidStage` and `converseExchange` is `voidExchange` with `prefix: Void`. Only a name that starts there and
    /// goes on with a capital is the kit's, so the app's words are left alone.
    static func renaming(_ text: String, prefix: String) -> String {
        guard !prefix.isEmpty, prefix != "Converse" else { return text }
        let lower = prefix.prefix(1).lowercased() + prefix.dropFirst()
        var out = text
        for (word, replacement) in [("Converse", prefix), ("converse", lower)] {
            guard let expression = try? NSRegularExpression(pattern: "(?<![A-Za-z0-9_])" + word + "(?=[A-Z])") else { continue }
            out = expression.stringByReplacingMatches(in: out, range: NSRange(out.startIndex..., in: out),
                                                      withTemplate: NSRegularExpression.escapedTemplate(for: replacement))
        }
        return out
    }
}
