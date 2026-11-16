extension Template {
    static let stage = #"""
import SwiftUI

/// The conversation's stage: one exchange at a time on an empty stage. A prompt sent leaves the last exchange rising
/// away as the new one arrives; its reply is typed out with a cursor, then settles with its sources' phrases brushed in
/// their owner's colours. A slow orb sits behind, a glass input is pinned to the bottom, and glass bands soften the
/// screen's edges. The stage opens its own sheets (the transcript, a reply's sources, the weave) and leaves every other
/// route to the app.
///
///     ConverseStage(exchanges: chat.state.exchanges, send: { try await chat.send(text: $0) })
///
/// `exchanges` is the conversation, oldest first; `send` makes the app add one (its reply may come later). `load`
/// fetches the conversation when a launch opens on exchanges the list does not hold yet. `leading` draws the bar's
/// leading button, green while `leadingActive`; `listen` draws a microphone in the input, filled while `listening`.
/// `documents` shows documents by their ids, from a stroke or a source; the stage lists them itself without it.
struct ConverseStage<Documents: View>: View {
    private let exchanges: [ConverseExchange]
    private let readings: [ConverseReading]
    private let send: @MainActor (String) async throws -> Void
    private let load: (@MainActor () async throws -> Void)?
    private let leading: (@MainActor () -> Void)?
    private let leadingActive: Bool
    private let listen: (@MainActor () -> Void)?
    private let listening: Bool
    private let documents: (([String]) -> Documents)?

    /// An exchange on the stage.
    private struct Slot: Equatable {
        let id: Int
        /// The exchange it shows; nil until the app's list holds the one a send made.
        var exchangeID: String?
        var prompt: String
        /// When it was sent; nil for one that was complete when it appeared.
        var sentAt: Date?
    }

    private enum Sheet: Identifiable, Equatable {
        case transcript
        case sources(String)
        case documents([String])

        var id: String {
            switch self {
            case .transcript: return "transcript"
            case .sources(let exchange): return "sources." + exchange
            case .documents(let ids): return "documents." + ids.joined(separator: ",")
            }
        }
    }

    /// The exchanges the stage holds, by id: a launch's and those sent since. Nil while it follows the app's list.
    @State private var held: [String]?
    /// The ids the list held when the last send began: one not among them is that send's exchange.
    @State private var before: Set<String> = []
    @State private var current: Slot?
    @State private var leaving: Slot?
    @State private var nextSlot = 0
    @State private var draft = ""
    @State private var replying = false
    @State private var sheet: Sheet?
    @State private var scrolled = false
    @State private var launch: ConverseLaunch?
    @State private var started = false
    @FocusState private var focused: Bool

    init<Exchange: ConverseExchangeRepresentable>(
        exchanges: [Exchange],
        readings: [any ConverseReadingRepresentable] = ConverseReadings.all,
        send: @escaping @MainActor (String) async throws -> Void,
        load: (@MainActor () async throws -> Void)? = nil,
        leading: (@MainActor () -> Void)? = nil,
        leadingActive: Bool = false,
        listen: (@MainActor () -> Void)? = nil,
        listening: Bool = false,
        @ViewBuilder documents: @escaping ([String]) -> Documents
    ) {
        self.exchanges = exchanges.map(\.converseExchange)
        self.readings = readings.map(\.converseReading)
        self.send = send
        self.load = load
        self.leading = leading
        self.leadingActive = leadingActive
        self.listen = listen
        self.listening = listening
        self.documents = documents
    }

    var body: some View {
        ZStack {
            ConverseLook.background
                .ignoresSafeArea()
            ConverseOrb()
                .ignoresSafeArea(.keyboard)
            VStack(spacing: 0) {
                stage
                    .ignoresSafeArea(.keyboard)
                ConversePill(text: $draft, placeholder: {{s:stage.placeholder}}, canSend: canSend, focused: $focused, send: { submit() },
                             listen: listen, listening: listening)
                    .padding(.horizontal, {{n:pill.inset}})
                    .padding(.bottom, {{n:pill.inset}})
            }
            ConverseGlassEdge(edge: .top)
                .opacity(scrolled ? 1 : 0)
                .animation(.easeInOut(duration: {{n:edge.fade}}), value: scrolled)
            #if os(iOS)
            // In front of everything, the input too: content and the pill sink softly into the tab bar.
            ConverseGlassEdge(edge: .bottom)
            #endif
        }
        .modifier(ConverseInlineTitle())
        .toolbar {
//@if title
            ConverseBarTitle(text: {{s:stage.title}})
//@endif
            if let leading {
                ToolbarItem(placement: ConversePlatform.leading) {
                    Button {
                        ConversePlatform.tap()
                        leading()
                    } label: {
                        Image(systemName: {{y:leading}})
                            .font(.headline)
                            .foregroundStyle(leadingActive ? Color.green.gradient : ConverseLook.accent.gradient)
                    }
                    .accessibilityLabel({{s:stage.leadingLabel}})
                }
            }
            if focused {
                ToolbarItem(placement: ConversePlatform.trailing) {
                    Button {
                        focused = false
                    } label: {
                        Image(systemName: {{y:keyboard}})
                            .foregroundStyle(ConverseLook.accent)
                    }
                    .accessibilityLabel({{s:stage.keyboardLabel}})
                }
            }
            if !conversation.isEmpty {
                ToolbarItem(placement: ConversePlatform.trailing) {
                    Button {
                        ConversePlatform.tap()
                        sheet = sheet == .transcript ? nil : .transcript
                    } label: {
                        Image(systemName: sheet == .transcript ? {{y:close}} : {{y:echoes}})
                            .font(.body)
                            .foregroundStyle(ConverseLook.accent)
                    }
                    .accessibilityLabel({{s:stage.echoesLabel}})
                }
            }
        }
        .sheet(item: $sheet, onDismiss: { launch = nil }) { shown in
            switch shown {
            case .transcript:
                ConverseTranscript(exchanges: conversation, readings: readings, documents: documents, opensWeave: launch?.opensWeave == true)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
            case .sources(let id):
                ConverseSources(exchange: exchanges.first { $0.id == id }, documents: documents, opening: launch?.group)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
            case .documents(let ids):
                NavigationStack {
                    ConverseRouteView(route: .documents(ids), exchanges: conversation, documents: documents, close: { sheet = nil })
                }
                .tint(ConverseLook.accent)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear { start() }
        .task { await loadForLaunch() }
        .onChange(of: exchanges.map(\.id)) { _, ids in
            applyLaunch()
            adopt(ids)
            follow()
        }
    }

    // MARK: The stage

    /// The dot while nothing is on the stage; else the exchange leaving, behind the one shown.
    private var stage: some View {
        ZStack {
            if current == nil && leaving == nil {
                ConverseIdleDot()
                    .transition(.opacity.animation(.easeInOut(duration: {{n:idle.fade}})))
            }
            if let leaving {
                let exchange = exchange(for: leaving)
                ConverseStageExchange(prompt: exchange?.prompt ?? leaving.prompt, exchange: exchange, sentAt: nil, leaving: true)
                    .id("leaving-\(leaving.id)")
            }
            if let current {
                let exchange = exchange(for: current)
                ConverseStageExchange(
                    prompt: exchange?.prompt ?? current.prompt,
                    exchange: exchange,
                    sentAt: current.sentAt,
                    leaving: false,
                    onSettled: { replying = false },
                    onReply: { if let exchange { open(.sources(exchange.id)) } },
                    onStroke: { owner in strokeTapped(owner, in: exchange) },
                    onScrolled: { scrolled = $0 }
                )
                .id("current-\(current.id)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, {{n:stage.side}})
        .padding(.top, {{n:stage.top}})
        .padding(.bottom, {{n:stage.bottom}})
    }

    // MARK: What it shows

    /// The conversation the stage holds, oldest first.
    private var conversation: [ConverseExchange] {
        guard let held else { return exchanges }
        return held.compactMap { id in exchanges.first { $0.id == id } }
    }

    private func exchange(for slot: Slot) -> ConverseExchange? {
        slot.exchangeID.flatMap { id in exchanges.first { $0.id == id } }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !replying
    }

    // MARK: Sending

    private func submit() {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !replying else { return }
        ConversePlatform.tap()
        draft = ""
        replying = true
        scrolled = false
        before = Set(exchanges.map(\.id))
        if held == nil { held = exchanges.map(\.id) }
        if let shown = current {
            // The shown exchange leaves as plain text, its strokes dropped, and is gone a little after it has faded.
            leaving = shown
            let leavingID = shown.id
            Task {
                try? await Task.sleep(for: .seconds({{n:leave.remove}}))
                if leaving?.id == leavingID { leaving = nil }
            }
        }
        nextSlot += 1
        current = Slot(id: nextSlot, exchangeID: nil, prompt: prompt, sentAt: Date())
        Task {
            do {
                try await send(prompt)
            } catch {
                // Nothing was made of it: the prompt goes back into the field.
                if current?.exchangeID == nil {
                    current = nil
                    draft = prompt
                    replying = false
                }
            }
        }
    }

    /// A send's exchange, once the app's list holds it: the slot shows it, and the stage holds it.
    private func adopt(_ ids: [String]) {
        guard var slot = current, slot.exchangeID == nil, slot.sentAt != nil else { return }
        let made = ids.filter { !before.contains($0) }
        guard let id = made.last else { return }
        slot.exchangeID = id
        current = slot
        if var kept = held {
            for new in made where !kept.contains(new) { kept.append(new) }
            held = kept
        }
    }

    /// With no send under way, the stage shows the conversation's last exchange, settled. Complete already, it is
    /// settled at once; it still arrives, and its strokes still fade in.
    private func follow() {
        guard current?.sentAt == nil || current?.exchangeID != nil else { return }
        guard !replying else { return }
        let last = conversation.last
        guard current?.exchangeID != last?.id else { return }
        scrolled = false
        guard let last else {
            current = nil
            return
        }
        nextSlot += 1
        current = Slot(id: nextSlot, exchangeID: last.id, prompt: last.prompt, sentAt: nil)
    }

    // MARK: Taps

    private func open(_ shown: Sheet) {
        ConversePlatform.tap()
        sheet = shown
    }

    private func strokeTapped(_ owner: ConverseOwner, in exchange: ConverseExchange?) {
        let ids = owner.shownDocuments.map(\.id)
        if ids.isEmpty, let exchange {
            open(.sources(exchange.id))
        } else {
            open(.documents(ids))
        }
    }

    // MARK: Launch

    private func start() {
        guard !started else { return }
        started = true
        launch = ConverseLaunch.current
        if launch == .empty { held = [] }
        applyLaunch()
        follow()
    }

    /// The exchanges a launch opens on, once the list holds them: the stage holds those, and its sheets open.
    private func applyLaunch() {
        guard let launch, launch != .empty, held == nil || held?.isEmpty == true, current?.sentAt == nil else { return }
        let indices = launch.indices
        guard let highest = indices.max(), highest < exchanges.count else { return }
        let ids = indices.map { exchanges[$0].id }
        held = ids
        follow()
        switch launch {
        case .transcript, .weave:
            sheet = .transcript
        case .sources, .source:
            if let last = ids.last { sheet = .sources(last) }
        case .empty, .reply:
            break
        }
    }

    /// Fetches the conversation when a launch opens on exchanges the list does not hold yet.
    private func loadForLaunch() async {
        guard let load, let wanted = ConverseLaunch.current?.indices.max(), wanted >= exchanges.count else { return }
        try? await load()
    }
}

extension ConverseStage where Documents == EmptyView {
    init<Exchange: ConverseExchangeRepresentable>(
        exchanges: [Exchange],
        readings: [any ConverseReadingRepresentable] = ConverseReadings.all,
        send: @escaping @MainActor (String) async throws -> Void,
        load: (@MainActor () async throws -> Void)? = nil,
        leading: (@MainActor () -> Void)? = nil,
        leadingActive: Bool = false,
        listen: (@MainActor () -> Void)? = nil,
        listening: Bool = false
    ) {
        self.exchanges = exchanges.map(\.converseExchange)
        self.readings = readings.map(\.converseReading)
        self.send = send
        self.load = load
        self.leading = leading
        self.leadingActive = leadingActive
        self.listen = listen
        self.listening = listening
        self.documents = nil
    }
}

/// An exchange on the stage, in a column of its own: centred in the stage while it is short, scrolling from the top
/// once it is tall. It arrives from below as it appears, or, leaving, rises away and dissolves.
struct ConverseStageExchange: View {
    let prompt: String
    let exchange: ConverseExchange?
    let sentAt: Date?
    let leaving: Bool
    var onSettled: () -> Void = {}
    var onReply: () -> Void = {}
    var onStroke: ((ConverseOwner) -> Void)? = nil
    var onScrolled: (Bool) -> Void = { _ in }

    @State private var opacity: Double
    @State private var offset: CGFloat
    @State private var blur: CGFloat
    @State private var scale: CGFloat = 1
    @State private var contentHeight: CGFloat = 0

    init(prompt: String, exchange: ConverseExchange?, sentAt: Date?, leaving: Bool, onSettled: @escaping () -> Void = {},
         onReply: @escaping () -> Void = {}, onStroke: ((ConverseOwner) -> Void)? = nil, onScrolled: @escaping (Bool) -> Void = { _ in }) {
        self.prompt = prompt
        self.exchange = exchange
        self.sentAt = sentAt
        self.leaving = leaving
        self.onSettled = onSettled
        self.onReply = onReply
        self.onStroke = onStroke
        self.onScrolled = onScrolled
        _opacity = State(initialValue: leaving ? 1 : 0)
        _offset = State(initialValue: leaving ? 0 : {{n:arrive.drop}})
        _blur = State(initialValue: leaving ? 0 : {{n:arrive.blur}})
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                ConverseExchangeView(prompt: prompt, exchange: exchange, sentAt: sentAt, brushed: !leaving,
                                     onSettled: onSettled, onReply: onReply, onStroke: onStroke)
                    .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { contentHeight = $0 }
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: Bool.self, of: { $0.frame(in: .scrollView).minY < -0.5 }) { moved in
                        if !leaving { onScrolled(moved) }
                    }
            }
            .scrollDisabled(contentHeight <= geometry.size.height)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .modifier(ConverseClearBar())
        .opacity(opacity)
        .offset(y: offset)
        .blur(radius: blur)
        .scaleEffect(scale)
        .allowsHitTesting(!leaving)
        .onAppear {
            if leaving {
                withAnimation(.easeIn(duration: {{n:leave.duration}})) {
                    opacity = 0
                    offset = {{-n:leave.rise}}
                    blur = {{n:leave.blur}}
                    scale = {{n:leave.scale}}
                }
            } else {
                withAnimation(.timingCurve({{n:arrive.curve}}, duration: {{n:arrive.duration}})) {
                    opacity = 1
                    offset = 0
                    blur = 0
                }
            }
        }
    }
}

private struct ConverseStagePreview: View {
    @State private var exchanges = Array(ConverseSamples.exchanges.prefix(1))

    var body: some View {
        NavigationStack {
            ConverseStage(exchanges: exchanges, readings: ConverseSamples.readings, send: { text in
                try await Task.sleep(for: .seconds(0.5))
                exchanges.append(ConverseExchange(prompt: text, reply: ConverseSamples.exchanges[1].reply))
            }, leading: {})
        }
    }
}

#Preview {
    ConverseStagePreview()
}
"""#
}
