import Foundation

/// The apps the gated build writes the kit into, each with its own types and the page body a host would write:
/// Seer (its call from `Schema/examples/seer.json`, its types in a package of their own, Swift 6), a tutor (the
/// other example call, prefixed, Swift 5) and the least call (no lines at all, the kit's own values, Swift 6).
enum ConverseApps {
    // MARK: Seer

    /// SeerKit as the app's client package declares it, as ModelsAgent writes its types: what the Seer call's mapping
    /// lines read. The owners of one reply are values with no `id`; a group is told apart by its name.
    static let seerKit = #"""
    import Foundation

    public struct Exchange: Codable, Hashable, Identifiable, Sendable {
        public var id: String
        public var prompt: String
        public var reply: String
        public var highlights: [Highlight]
        public var owners: [Contributor]

        public init(id: String, prompt: String, reply: String, highlights: [Highlight], owners: [Contributor]) {
            self.id = id
            self.prompt = prompt
            self.reply = reply
            self.highlights = highlights
            self.owners = owners
        }
    }

    public struct Highlight: Codable, Hashable, Sendable {
        public var phrase: String
        public var ownerId: String

        public init(phrase: String, ownerId: String) {
            self.phrase = phrase
            self.ownerId = ownerId
        }
    }

    /// An owner's part in one reply.
    public struct Contributor: Codable, Hashable, Sendable {
        public var ownerId: String
        public var name: String
        public var royalty: Int
        public var isAccount: Bool
        public var tone: Int
        public var documents: [SourceDocument]
        public var groups: [SourceGroup]

        public init(ownerId: String, name: String, royalty: Int, isAccount: Bool, tone: Int, documents: [SourceDocument], groups: [SourceGroup]) {
            self.ownerId = ownerId
            self.name = name
            self.royalty = royalty
            self.isAccount = isAccount
            self.tone = tone
            self.documents = documents
            self.groups = groups
        }
    }

    /// A document a reply drew on, and how much.
    public struct SourceDocument: Codable, Hashable, Sendable {
        public var documentId: String
        public var text: String
        public var influence: Int

        public init(documentId: String, text: String, influence: Int) {
            self.documentId = documentId
            self.text = text
            self.influence = influence
        }
    }

    /// A group of an owner's documents a reply drew on.
    public struct SourceGroup: Codable, Hashable, Sendable {
        public var name: String
        public var summary: String
        public var tags: [String]
        public var documents: [SourceDocument]

        public init(name: String, summary: String, tags: [String], documents: [SourceDocument]) {
            self.name = name
            self.summary = summary
            self.tags = tags
            self.documents = documents
        }
    }

    /// The mock chat's six exchanges, in order.
    public enum MockExchanges {
        static let you = "owner-ada"

        public static let all: [Exchange] = [
            Exchange(
                id: "exchange-1",
                prompt: "What do my notes say about getting to Mars?",
                reply: "Mars is the fourth planet from the Sun, a cold desert world with a thin atmosphere made mostly of carbon dioxide. Perseverance landed there in February 2021 and carried Ingenuity, the helicopter that made the first powered flight on another planet.\n\nGetting people there is the harder problem. Starship is being built to carry crew and cargo to the Moon, Mars and beyond, and a transfer window opens only about every twenty-six months, when a low-energy path between the two orbits lines up.",
                highlights: [
                    Highlight(phrase: "a cold desert world with a thin atmosphere made mostly of carbon dioxide", ownerId: you),
                    Highlight(phrase: "the helicopter that made the first powered flight on another planet", ownerId: you),
                    Highlight(phrase: "carry crew and cargo to the Moon, Mars and beyond", ownerId: you),
                    Highlight(phrase: "a transfer window opens only about every twenty-six months", ownerId: "owner-tomas"),
                ],
                owners: [
                    Contributor(ownerId: you, name: "Ada Marlow", royalty: 62, isAccount: true, tone: 0, documents: [
                        SourceDocument(documentId: "space-001", text: "Mars is the fourth planet from the Sun and the second-smallest planet in the Solar System. It has a thin atmosphere composed mostly of carbon dioxide.", influence: 41),
                        SourceDocument(documentId: "space-002", text: "The Perseverance rover landed on Mars in February 2021, carrying the Ingenuity helicopter which achieved the first powered flight on another planet.", influence: 33),
                        SourceDocument(documentId: "space-003", text: "SpaceX's Starship is designed to carry crew and cargo to Earth orbit, the Moon, Mars, and beyond. It is the most powerful rocket ever built.", influence: 26),
                    ], groups: []),
                    Contributor(ownerId: "owner-tomas", name: "Tomas Vey", royalty: 38, isAccount: false, tone: 1, documents: [], groups: [
                        SourceGroup(name: "Orbital Mechanics", summary: "Transfers, windows and delta-v budgets worked by hand.", tags: ["space", "physics"], documents: [
                            SourceDocument(documentId: "orbital-mechanics-001", text: "Transfers, windows and delta-v budgets worked by hand. Document 1 of 8.", influence: 70),
                            SourceDocument(documentId: "orbital-mechanics-002", text: "Transfers, windows and delta-v budgets worked by hand. Document 2 of 8.", influence: 30),
                        ]),
                    ]),
                ]
            ),
            Exchange(id: "exchange-2", prompt: "What is dharma?", reply: "Dharma is a concept of cosmic order, duty, and righteousness.", highlights: [], owners: []),
            Exchange(
                id: "exchange-3",
                prompt: "Why does sourdough take so long?",
                reply: "A starter is fed daily for a week before it gathers enough wild yeast; time does the rest.",
                highlights: [
                    Highlight(phrase: "fed daily for a week before it gathers enough wild yeast", ownerId: you),
                    Highlight(phrase: "time does the rest", ownerId: "owner-mara"),
                ],
                owners: [
                    Contributor(ownerId: you, name: "Ada Marlow", royalty: 60, isAccount: true, tone: 0, documents: [
                        SourceDocument(documentId: "cook-003", text: "Feed the starter daily for a week.", influence: 100),
                    ], groups: []),
                    Contributor(ownerId: "owner-mara", name: "Mara Ellison", royalty: 40, isAccount: false, tone: 4, documents: [], groups: [
                        SourceGroup(name: "Sourdough Lab", summary: "Starters, flours and slow ferments.", tags: ["baking", "bread"], documents: [
                            SourceDocument(documentId: "sourdough-lab-001", text: "Starters, flours and slow ferments.", influence: 100),
                        ]),
                    ]),
                ]
            ),
            Exchange(
                id: "exchange-4",
                prompt: "What made the Silk Road matter?",
                reply: "It carried more than silk.\n\nThe routes joined China to the Mediterranean, and along them moved spices, precious metals and ideas.",
                highlights: [
                    Highlight(phrase: "joined China to the Mediterranean", ownerId: you),
                    Highlight(phrase: "spices, precious metals and ideas", ownerId: "owner-priya"),
                ],
                owners: [
                    Contributor(ownerId: you, name: "Ada Marlow", royalty: 54, isAccount: true, tone: 0, documents: [
                        SourceDocument(documentId: "hist-004", text: "The Silk Road joined China to the Mediterranean.", influence: 100),
                    ], groups: []),
                    Contributor(ownerId: "owner-priya", name: "Priya Nand", royalty: 46, isAccount: false, tone: 2, documents: [], groups: [
                        SourceGroup(name: "Roman Roads", summary: "How an empire moved goods, armies and news.", tags: ["history", "trade"], documents: [
                            SourceDocument(documentId: "roman-roads-001", text: "How an empire moved goods, armies and news.", influence: 100),
                        ]),
                    ]),
                ]
            ),
            Exchange(
                id: "exchange-5",
                prompt: "What is counterpoint, really?",
                reply: "Two melodies that keep their independence while agreeing on the harmony.\n\nEach line has its own rhythm and contour, yet neither makes full sense alone.",
                highlights: [
                    Highlight(phrase: "keep their independence while agreeing on the harmony", ownerId: you),
                    Highlight(phrase: "neither makes full sense alone", ownerId: "owner-jun"),
                ],
                owners: [
                    Contributor(ownerId: you, name: "Ada Marlow", royalty: 65, isAccount: true, tone: 0, documents: [
                        SourceDocument(documentId: "music-003", text: "Counterpoint keeps each line independent.", influence: 100),
                    ], groups: []),
                    Contributor(ownerId: "owner-jun", name: "Jun Okafor", royalty: 35, isAccount: false, tone: 3, documents: [], groups: [
                        SourceGroup(name: "Jazz Voicings", summary: "Chord shapes and inner lines for standards.", tags: ["jazz", "harmony"], documents: [
                            SourceDocument(documentId: "jazz-voicings-001", text: "Chord shapes and inner lines for standards.", influence: 100),
                        ]),
                    ]),
                ]
            ),
            Exchange(
                id: "exchange-6",
                prompt: "What is overfitting?",
                reply: "A model overfits when it learns its training data too well, noise included, and then fails on anything it has not seen.\n\nThe remedy is restraint: **simpler models** and held-out data.",
                highlights: [
                    Highlight(phrase: "learns its training data too well, noise included", ownerId: you),
                    Highlight(phrase: "fails on anything it has not seen", ownerId: you),
                ],
                owners: [
                    Contributor(ownerId: you, name: "Ada Marlow", royalty: 100, isAccount: true, tone: 0, documents: [
                        SourceDocument(documentId: "ml-004", text: "Overfitting: the model learns the noise.", influence: 100),
                    ], groups: []),
                ]
            ),
        ]
    }
    """#

    /// DesignAgent's names, stood in: the fonts and colours the Seer call's `look` lines name.
    static let seerDesign = #"""
    import SwiftUI

    extension Font {
        static var brandTitle: Font { .system(size: 24, design: .serif) }
        static var brandBody: Font { .system(size: 20, design: .serif) }
        static var brandBody2: Font { .system(size: 18, design: .serif) }
        static var brandNote: Font { .system(size: 18, weight: .light, design: .serif) }
        static var brandNote2: Font { .system(size: 16, weight: .light, design: .serif) }
    }

    extension Color {
        static var accent: Color { Color(red: 174 / 255, green: 144 / 255, blue: 96 / 255) }
        #if canImport(UIKit)
        static var background: Color { Color(uiColor: .systemBackground) }
        #else
        static var background: Color { Color(nsColor: .windowBackgroundColor) }
        #endif
    }
    """#

    /// The Seer tab's page body, exactly as the host writes it: the same for every destination, the stage opening the rest.
    static let seerPageBody = "ConverseStage(exchanges: chat.state.exchanges, send: { try await chat.send(text: $0) }, load: { try await chat.load() }, leading: { layout.present(.world) })"

    /// The Seer tab's page, its body exactly as the host writes it, over stand-ins for the app's relays.
    static let seerPage = #"""
    import SwiftUI
    import SeerKit

    enum AppDestination: Hashable {
        case world
    }

    /// The chat service, stood in: the conversation, `send(text:)` and `load()`, as the app's relay calls them.
    @MainActor
    final class ChatService: ObservableObject {
        struct State {
            var exchanges: [Exchange] = []
        }

        @Published private(set) var state = State()

        @discardableResult
        func load() async throws -> [Exchange] {
            state.exchanges = MockExchanges.all
            return state.exchanges
        }

        @discardableResult
        func send(text: String) async throws -> [Exchange] {
            try await Task.sleep(for: .seconds(1.2))
            let next = MockExchanges.all[state.exchanges.count % MockExchanges.all.count]
            let made = Exchange(id: UUID().uuidString, prompt: text, reply: next.reply, highlights: next.highlights, owners: next.owners)
            state.exchanges.append(made)
            return [made]
        }
    }

    @MainActor
    final class LayoutService: ObservableObject {
        @Published var presented: AppDestination?

        func present(_ destination: AppDestination) {
            presented = destination
        }
    }

    /// The Seer tab's page, titled as GraniteAgent's blank page titles it: the stage's own title, inline, shows in the bar.
    struct Seer: View {
        @StateObject private var chat = ChatService()
        @StateObject private var layout = LayoutService()

        var body: some View {
            \#(seerPageBody)
                .navigationTitle("Seer")
        }
    }

    /// The tab the page is on, in its navigation stack, as the app's navigation opens it.
    struct SeerTabs: View {
        var body: some View {
            TabView {
                NavigationStack {
                    Seer()
                }
                .tabItem { Image(systemName: "circle") }
            }
        }
    }

    public enum SeerCheck {
        /// Every root view and the stage's parts, drawn offscreen from the app's own values: the names of those that
        /// drew nothing. The tabs are built, not drawn: an offscreen renderer stops on a TabView.
        @MainActor
        public static func run() -> (drawn: [String], failed: [String]) {
            let exchanges = MockExchanges.all.map(\.converseExchange)
            let views: [(String, AnyView)] = [
                ("stage", AnyView(NavigationStack { ConverseStage(exchanges: MockExchanges.all, send: { _ in }) })),
                ("exchange", AnyView(ConverseExchangeView(prompt: exchanges[0].prompt, exchange: exchanges[0], sentAt: nil))),
                ("brushed", AnyView(ConverseBrushedReply(exchange: exchanges[5]))),
                ("transcript", AnyView(ConverseTranscript(exchanges: Array(exchanges.prefix(1)), readings: ConverseReadings.all,
                                                          opensWeave: true, weaveLarge: true, weaveReading: "outward"))),
                ("sources", AnyView(ConverseSources(exchange: exchanges[0], opening: "Orbital Mechanics"))),
                ("sources.list", AnyView(NavigationStack { ConverseSourcesList(exchange: exchanges[0], close: {}) })),
                ("sources.empty", AnyView(NavigationStack { ConverseSourcesList(exchange: exchanges[1], close: {}) })),
                ("detail", AnyView(NavigationStack { ConverseSourceDetail(documents: exchanges[0].owners[1].groups[0].documents, close: {}) })),
                ("weave", AnyView(ConverseWeave(readings: ConverseReadings.all, entered: true))),
                ("weave.open", AnyView(ConverseWeave(readings: ConverseReadings.all, entered: true, open: "outward"))),
            ]
            return ConverseDraw.each(views)
        }
    }
    """#

    // MARK: A tutor

    static let tutorModels = #"""
    import Foundation

    struct Turn: Identifiable {
        let id: UUID
        var question: String
        var answer: String?
        var quotes: [Quote]
        var sources: [Source]
    }

    struct Quote: Hashable {
        var text: String
        var sourceID: UUID
    }

    struct Source: Identifiable, Hashable {
        let id: UUID
        var title: String
        var share: Double
        var pages: [Page]
    }

    struct Page: Identifiable, Hashable {
        let id: Int
        var body: String
        var weight: Double
    }

    enum TurnSamples {
        static let textbook = UUID()
        static let turns: [Turn] = [
            Turn(id: UUID(), question: "Why is the sky blue?",
                 answer: "Sunlight scatters off the air, and blue light scatters the most.\n\nAt sunset the light crosses more air, so the reds are left.",
                 quotes: [Quote(text: "blue light scatters the most", sourceID: textbook)],
                 sources: [Source(id: textbook, title: "Optics, Book One", share: 0.8, pages: [Page(id: 12, body: "Rayleigh scattering grows as the wavelength shrinks.", weight: 1.0)])]),
            Turn(id: UUID(), question: "And clouds?", answer: nil, quotes: [], sources: []),
        ]
    }
    """#

    static let tutorPage = #"""
    import SwiftUI

    /// The tutor's page: its turns held in state, a send that adds one.
    struct TutorPage: View {
        @State private var turns = TurnSamples.turns

        var body: some View {
            NavigationStack {
                TutorStage(exchanges: turns, send: { text in
                    turns.append(Turn(id: UUID(), question: text, answer: "Ask again tomorrow.", quotes: [], sources: []))
                })
            }
        }
    }

    public enum TutorCheck {
        @MainActor
        public static func run() -> (drawn: [String], failed: [String]) {
            let turns = TurnSamples.turns.map(\.tutorExchange)
            return TutorDraw.each([
                ("page", AnyView(TutorPage())),
                ("exchange", AnyView(TutorExchangeView(prompt: turns[0].prompt, exchange: turns[0], sentAt: nil))),
                ("transcript", AnyView(TutorTranscript(exchanges: turns, readings: TutorReadings.all))),
                ("sources", AnyView(TutorSources(exchange: turns[0]))),
                ("weave", AnyView(TutorWeave(readings: TutorReadings.all, entered: true))),
            ])
        }
    }
    """#

    // MARK: The least call

    static let leastPage = #"""
    import SwiftUI

    /// A page over the kit's own values, with nothing mapped.
    struct LeastPage: View {
        @State private var exchanges: [ConverseExchange] = []

        var body: some View {
            NavigationStack {
                ConverseStage(exchanges: exchanges, send: { exchanges.append(ConverseExchange(prompt: $0, reply: "Noted.")) })
            }
        }
    }

    public enum LeastCheck {
        @MainActor
        public static func run() -> (drawn: [String], failed: [String]) {
            ConverseDraw.each([
                ("page", AnyView(LeastPage())),
                ("exchange", AnyView(ConverseExchangeView(prompt: ConverseSamples.exchanges[0].prompt, exchange: ConverseSamples.exchanges[0], sentAt: nil))),
                ("transcript", AnyView(ConverseTranscript(exchanges: ConverseSamples.exchanges, readings: ConverseSamples.readings))),
                ("sources", AnyView(ConverseSources(exchange: ConverseSamples.exchanges[0]))),
                ("weave", AnyView(ConverseWeave(readings: ConverseSamples.readings, entered: true))),
            ])
        }
    }
    """#

    /// Draws views offscreen at a phone's size; `__PREFIX__` is the kit's prefix in that app.
    static let draw = #"""
    import ImageIO
    import SwiftUI

    enum __PREFIX__Draw {
        /// Each view drawn offscreen at an iPhone's size; with `CONVERSE_SHOTS=<folder>`, in light and dark, saved there.
        @MainActor
        static func each(_ views: [(String, AnyView)]) -> (drawn: [String], failed: [String]) {
            let shots = ProcessInfo.processInfo.environment["CONVERSE_SHOTS"]
            // The app's module names the pictures: `Seer.ConverseDraw` saves Seer-stage-light.png.
            let app = String(reflecting: __PREFIX__Draw.self).components(separatedBy: ".").first ?? "__PREFIX__"
            var drawn: [String] = []
            var failed: [String] = []
            for (name, view) in views {
                var images = 0
                for scheme in shots == nil ? [ColorScheme.light] : [.light, .dark] {
                    let framed = view.frame(width: 402, height: 874)
                        .background(scheme == .dark ? Color.black : Color.white)
                        .environment(\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: framed)
                    renderer.scale = 2
                    guard let image = renderer.cgImage else { continue }
                    images += 1
                    guard let shots else { continue }
                    let url = URL(fileURLWithPath: shots).appendingPathComponent("\(app)-\(name)-\(scheme == .dark ? "dark" : "light").png")
                    if let file = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) {
                        CGImageDestinationAddImage(file, image, nil)
                        CGImageDestinationFinalize(file)
                    }
                }
                if images > 0 { drawn.append(name) } else { failed.append(name) }
            }
            return (drawn, failed)
        }
    }
    """#
}
