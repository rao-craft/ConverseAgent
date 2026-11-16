import Foundation
import XCTest
@testable import ConverseAgent

/// The templates held to the catalog and the keys, so no call can write a file with a marker, an empty placeholder,
/// a view the catalog does not know, or a name the prefix does not reach.
final class TemplateTests: XCTestCase {
    private func matches(_ pattern: String, in text: String, group: Int = 0) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            Range($0.range(at: group), in: text).map { String(text[$0]) }
        }
    }

    func testEveryTemplateRendersWithAndWithoutATitleAndFillsFromTheDefaults() throws {
        for part in KitCatalog.parts {
            for flags in [Set(["title"]), Set<String>()] {
                let rendered = try TemplateRender.render(part.template, flags: flags)
                XCTAssertFalse(rendered.contains("//@"), "\(part.name) keeps a marker")
                let filled = try TemplateFill.fill(rendered, with: .defaults)
                XCTAssertFalse(filled.contains("{{"), "\(part.name) keeps a placeholder")
            }
        }
    }

    func testEveryKeyIsReadByATemplateAndEveryPlaceholderNamesAKey() {
        let placeholders = Set(KitCatalog.parts.flatMap { TemplateFill.placeholders(in: $0.template) })
        for key in TuningKey.all where key.name != "palette" {
            XCTAssertTrue(placeholders.contains("n:" + key.name) || placeholders.contains("c:" + key.name), "no template reads \(key.name)")
        }
        for key in StringKey.all { XCTAssertTrue(placeholders.contains("s:" + key.name), "no template says \(key.name)") }
        for key in SymbolKey.all { XCTAssertTrue(placeholders.contains("y:" + key.name), "no template draws \(key.name)") }
        for placeholder in placeholders {
            let parts = placeholder.split(separator: ":", maxSplits: 1).map(String.init)
            switch parts[0] {
            case "n", "c": XCTAssertNotNil(TuningKey.named(parts[1]), placeholder)
            case "s": XCTAssertNotNil(StringKey.named(parts[1]), placeholder)
            default: XCTAssertNotNil(SymbolKey.named(parts[1]), placeholder)
            }
        }
    }

    func testEveryViewATemplateDeclaresIsInTheCatalog() {
        for part in KitCatalog.parts {
            let declared = matches(#"(?m)^struct Converse([A-Za-z]+)(?:<[^>]*>)?: View(?![A-Za-z])"#, in: part.template, group: 1)
            XCTAssertEqual(Set(declared), Set(part.views), "\(part.name) declares \(declared)")
        }
        for root in KitCatalog.roots {
            XCTAssertTrue(KitCatalog.parts.contains { $0.views.first == root }, "\(root) is the first view of its file")
        }
    }

    /// Every type the kit declares starts with `Converse`, so the prefix renames all of them; every kit name a template
    /// reads is declared by one of them or by an emitter.
    func testThePrefixReachesEveryNameTheKitDeclares() throws {
        let rendered = try KitCatalog.parts.map { try TemplateRender.render($0.template, flags: ["title"]) }.joined(separator: "\n")
        let declared = Set(matches(#"(?m)^(?:private |fileprivate )?(?:struct|enum|protocol|class|extension) ([A-Z][A-Za-z0-9]*)"#, in: rendered, group: 1))
        let foreign: Set<String> = ["Template", "View", "Color", "Font"]
        for name in declared.subtracting(foreign) { XCTAssertTrue(name.hasPrefix("Converse"), "\(name) is declared without the prefix") }
        let emitted = Set(KitCatalog.emitted.map { "Converse" + $0 })
        for name in Set(matches(#"\bConverse[A-Z][A-Za-z0-9]*"#, in: rendered)) {
            XCTAssertTrue(declared.contains(name) || emitted.contains(name), "\(name) is read and never declared")
        }
        let renamed = TemplateRender.renaming(rendered, prefix: "Void")
        XCTAssertTrue(matches(#"(?<![A-Za-z0-9_])[Cc]onverse[A-Z]"#, in: renamed).isEmpty, "a kit name keeps Converse")
        XCTAssertTrue(renamed.contains("struct VoidStage<Documents: View>: View"))
        XCTAssertTrue(renamed.contains("var voidExchange: VoidExchange"))
        XCTAssertEqual(TemplateRender.renaming("ConverseStage, conversed, Conversely, converseExchange", prefix: "Void"),
                       "VoidStage, conversed, Conversely, voidExchange", "only the kit's names")
    }

    func testEveryRoleHasItsProtocolAndConversionsInTheValues() {
        let values = Template.values
        for role in ConverseRole.allCases {
            XCTAssertTrue(values.contains("protocol \(role.protocolName()) {\n    var \(role.member()): \(role.valueType()) { get }"), role.rawValue)
            XCTAssertTrue(values.contains("static func \(role.plural)<Item: \(role.protocolName())>(_ value: [Item])"), role.rawValue)
            for property in role.properties {
                XCTAssertTrue(values.contains("static func \(property.kind.conversion)"), "\(role).\(property.key) reads through \(property.kind.conversion)")
            }
        }
    }

    func testEveryViewHasAPreviewAndEveryIconOnlyControlALabel() {
        for part in KitCatalog.parts where !part.views.isEmpty {
            XCTAssertTrue(part.template.contains("#Preview"), "\(part.name) has a preview")
        }
        let all = KitCatalog.parts.map(\.template).joined(separator: "\n")
        let images = matches(#"Image\(systemName: \{\{y:([a-z]+)\}\}"#, in: all, group: 1)
        for symbol in Set(images) where !["document", "person", "empty"].contains(symbol) {
            XCTAssertTrue(all.contains("{{y:\(symbol)}}") && all.contains(".accessibilityLabel("), "\(symbol) is labelled")
        }
        XCTAssertEqual(matches(#"\.accessibilityLabel\("#, in: all).count, 6, "leading, keyboard, echoes, send, microphone, weave")
    }
}
