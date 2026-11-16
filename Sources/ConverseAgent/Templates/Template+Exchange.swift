extension Template {
    static let exchangeView = #"""
import SwiftUI

/// One exchange on the stage: the prompt, and below it the reply in each of its states. While the reply is thought of,
/// three dots; once it is in (and the stage has cleared), it is typed out a character at a time with a cursor; then
/// it settles, and its phrases are brushed. An exchange that was complete when it appeared is settled at once.
struct ConverseExchangeView: View {
    let prompt: String
    let exchange: ConverseExchange?
    /// When it was sent; nil for an exchange that was complete when it appeared.
    let sentAt: Date?
    /// Whether its phrases are brushed: a leaving exchange is plain text.
    let brushed: Bool
    var onSettled: () -> Void = {}
    var onReply: () -> Void = {}
    var onStroke: ((ConverseOwner) -> Void)? = nil

    /// How many characters of the reply are shown while it is typed out; nil before and after.
    @State private var shown: Int?
    @State private var settled: Bool
    @State private var cursorOn = true

    init(prompt: String, exchange: ConverseExchange?, sentAt: Date?, brushed: Bool = true, onSettled: @escaping () -> Void = {},
         onReply: @escaping () -> Void = {}, onStroke: ((ConverseOwner) -> Void)? = nil) {
        self.prompt = prompt
        self.exchange = exchange
        self.sentAt = sentAt
        self.brushed = brushed
        self.onSettled = onSettled
        self.onReply = onReply
        self.onStroke = onStroke
        _settled = State(initialValue: sentAt == nil && exchange?.reply != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: {{n:column.gap}}) {
            Text(prompt)
                .font(ConverseLook.body)
                .foregroundStyle(Color.primary.opacity({{n:ink.body}}))
                .lineSpacing({{n:column.promptSpacing}})
                .kerning({{n:column.promptKerning}})
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            reply
        }
        .frame(maxWidth: {{n:column.width}}, alignment: .leading)
        .task(id: revealKey) { await reveal() }
        .task(id: shown != nil) { await blink() }
    }

    @ViewBuilder private var reply: some View {
        if let exchange, let text = exchange.reply, settled {
            if brushed, !exchange.highlights.isEmpty {
                ConverseBrushedReply(exchange: exchange, onReply: onReply, onStroke: onStroke)
            } else {
                ConverseReplyText(text: text)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onReply)
            }
        } else if let text = exchange?.reply, let shown {
            ConverseReplyText(paragraphs: ConverseMarkup.prefix(ConverseMarkup.paragraphs(text), shown), cursor: cursorOn)
        } else {
            ConverseThinkingDots()
                .padding(.leading, {{n:dots.inset}})
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var revealKey: String { (exchange?.id ?? "") + "\u{1F}" + (exchange?.reply ?? "\u{0}") }

    /// Types the reply out: it waits for the stage to clear, then shows one more character at a time.
    private func reveal() async {
        guard let text = exchange?.reply, !settled else { return }
        guard let sentAt else {
            settle()
            return
        }
        let total = ConverseMarkup.count(ConverseMarkup.paragraphs(text))
        if shown == nil {
            let wait = {{n:reveal.wait}} - Date().timeIntervalSince(sentAt)
            if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
            guard !Task.isCancelled else { return }
            shown = 0
        }
        while let count = shown, count < total {
            try? await Task.sleep(for: .milliseconds({{n:reveal.base}} + Double.random(in: 0...{{n:reveal.jitter}})))
            guard !Task.isCancelled else { return }
            shown = count + 1
        }
        settle()
    }

    private func settle() {
        shown = nil
        settled = true
        onSettled()
    }

    /// The cursor's blink while the reply is typed out: swapped with blank space, without animation.
    private func blink() async {
        guard shown != nil else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds({{n:reveal.cursor}}))
            guard !Task.isCancelled else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { cursorOn.toggle() }
        }
    }
}

#Preview {
    ConverseExchangeView(prompt: ConverseSamples.exchanges[0].prompt, exchange: ConverseSamples.exchanges[0], sentAt: Date())
        .padding()
}
"""#
}
