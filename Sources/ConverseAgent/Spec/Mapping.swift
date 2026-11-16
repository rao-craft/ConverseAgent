//  WHAT: One mapping line, read: which role an app's type takes, and how each thing the views show is read off it.

import Foundation

struct Mapping: Sendable, Equatable {
    /// How a right side reads its value.
    enum Source: Sendable, Equatable {
        /// A bare path, read off the value: `owner.name`, `stats?.royalty`.
        case path(String)
        /// Swift that may name `value`: `value.reply ?? ""`.
        case expression(String)
    }

    struct Assignment: Sendable, Equatable {
        let property: ConverseProperty
        let source: Source
    }

    let line: String
    let role: ConverseRole
    /// The app's type, as the line wrote it: `Exchange`, `SeerKit.Exchange`.
    let type: String
    /// How the type is identified, when the line says so (`id=slug`); nil when it has an `id` of its own.
    let id: Source?
    let assignments: [Assignment]

    /// The type's name for a file: `SeerKit.Exchange` is `SeerKitExchange`.
    var fileStem: String { type.replacingOccurrences(of: ".", with: "") }

    func source(of key: String) -> Source? { assignments.first { $0.property.key == key }?.source }
}
