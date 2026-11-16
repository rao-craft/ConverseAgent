import Foundation
import GraniteAgents

/// What a call answers, as `granite-answer/1`: the files written, as absolute paths, the views and how a page makes
/// them, and what the call made of the views and mapping lines it was asked for.
public struct ConverseResult: AgentAnswer, Equatable {
    /// The first file written.
    public var path: String?
    /// Every file written.
    public var paths: [String]
    /// The views written, by type name, root first.
    public var views: [String]
    /// One line a mapped type: `Exchange: exchange`.
    public var conformances: [String]
    /// Each root view's initializer, as a page calls it: what the host writes a page body from.
    public var initializers: [String]
    /// The launch states, one line a destination: `void.reply = reply(0)`.
    public var launch: [String]
    /// One sentence each: what the call left out or the app still has to do, and why.
    public var notes: [String]
    /// Each view and conformance written.
    public var made: [AgentMade]
    /// The root views, and one conformance a mapping line.
    public var expected: [AgentExpected]
    /// What it could only do in part.
    public var problems: [AgentProblem]

    public init(path: String?, paths: [String], views: [String], conformances: [String], initializers: [String],
                launch: [String], notes: [String], made: [AgentMade] = [], expected: [AgentExpected] = [],
                problems: [AgentProblem] = []) {
        self.path = path; self.paths = paths; self.views = views; self.conformances = conformances
        self.initializers = initializers; self.launch = launch; self.notes = notes; self.made = made
        self.expected = expected; self.problems = problems
    }
}
