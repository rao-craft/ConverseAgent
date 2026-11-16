import Foundation

/// What a run says as it goes.
public enum ConverseFrame: Sendable {
    /// The call was read: how many mapping lines, and how many files it writes.
    case read(mappings: Int, files: Int)
    /// The files are written.
    case written(ConverseResult)

    public var result: ConverseResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
