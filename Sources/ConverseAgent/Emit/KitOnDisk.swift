//  WHAT: The kit an earlier call left in the folder, read by its names: a later call writes every file again, so all
//        it needs is the prefix the earlier one gave, which the conformances already written use.
//  PIN:  ONE PREFIX A FOLDER. A call that names another is refused, since the conformances there would name
//        protocols no file declares any more.

import Foundation

enum KitOnDisk {
    /// The prefix of the kit in `folder`, read off its look, launch and stage files; nil when it holds none.
    static func prefix(in folder: URL) -> String? {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else { return nil }
        for name in names.sorted() where name.hasSuffix("Look.swift") {
            let prefix = String(name.dropLast("Look.swift".count))
            if SwiftName.isTypeName(prefix), names.contains(prefix + "Stage.swift"), names.contains(prefix + "Launch.swift") {
                return prefix
            }
        }
        return nil
    }
}
