//  WHAT: One conformance a mapping line: an extension that makes the app's type the kit's protocol, its one property
//        building the kit's value from the type's fields, each right side read through `ConverseValue` so its type
//        may be any the conversion takes (`royalty` an Int or a Double, `reply` a String or a String?).
//
//            extension Exchange: ConverseExchangeRepresentable {
//                var converseExchange: ConverseExchange {
//                    let value = self
//                    return ConverseExchange(
//                        id: ConverseValue.text(value.id),
//                        prompt: ConverseValue.text(value.prompt),
//                        …
//
//  PIN:  A WORD THE LINE LEAVES OUT IS NOT WRITTEN, so the value's own default shows (no reply, no owners, 0%).

import Foundation

enum ConformanceEmitter {
    struct File: Equatable {
        let name: String
        let text: String
    }

    /// `Exchange+ConverseExchange.swift`.
    static func fileName(_ mapping: Mapping, prefix: String) -> String {
        "\(mapping.fileStem)+\(mapping.role.valueType(prefix)).swift"
    }

    static func emit(_ mapping: Mapping, imports: [String], prefix: String) -> File {
        let role = mapping.role
        let value = prefix + "Value"
        var arguments: [String] = []
        if role.identified {
            arguments.append("id: \(value).text(\(swift(mapping.id ?? .path("id"))))")
        }
        for property in role.properties {
            guard let source = mapping.source(of: property.key) else { continue }
            arguments.append("\(property.key): \(value).\(property.kind.conversion)(\(swift(source)))")
        }
        let usesValue = arguments.contains { $0.range(of: #"(?<![A-Za-z0-9_.])value\b"#, options: .regularExpression) != nil }
        let line = mapping.line.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        var lines = ["import Foundation"] + imports.map { "import \($0)" }
        lines += [
            "",
            "/// `\(line.replacingOccurrences(of: "`", with: "'"))`",
            "extension \(mapping.type): \(role.protocolName(prefix)) {",
            "    var \(role.member(prefix)): \(role.valueType(prefix)) {",
        ]
        if usesValue { lines.append("        let value = self") }
        lines.append("        return \(role.valueType(prefix))(")
        for (index, argument) in arguments.enumerated() {
            lines.append("            \(argument)\(index == arguments.count - 1 ? "" : ",")")
        }
        lines += ["        )", "    }", "}"]
        return File(name: fileName(mapping, prefix: prefix), text: lines.joined(separator: "\n") + "\n")
    }

    /// A right side as Swift: a path read off `value`, or the line's own Swift.
    static func swift(_ source: Mapping.Source) -> String {
        switch source {
        case .path(let path): return "value." + path
        case .expression(let text): return text
        }
    }
}
