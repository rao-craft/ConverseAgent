extension Template {
    static let transcript = #"""
import SwiftUI

/// The conversation so far, newest first, as a sheet of its own: each prompt over its reply, a short rule between
/// exchanges. A tap on a reply pushes its sources; a long press copies a prompt or a reply. Its leading button opens
/// the weave.
struct ConverseTranscript<Documents: View>: View {
    let exchanges: [ConverseExchange]
    let readings: [ConverseReading]
    let documents: (([String]) -> Documents)?
    /// A launch opens the weave over it, its entrance done: at the large detent with `weaveLarge`, else the medium,
    /// and with `weaveReading`'s reading open when it names one.
    var opensWeave = false
    var weaveLarge = false
    var weaveReading: String? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var path: [ConverseRoute] = []
    /// The weave while it is up, handed to its sheet as the sheet's item. The body reads no state of the weave's, so a
    /// state set just before the sheet goes up reaches its content as the body last read it: a launch's weave stood at
    /// medium, offered both detents, with every state set for large.
    @State private var weave: WeaveSheet?

    /// The weave's sheet as it was opened: from the leading button at medium, a drag from large; from a launch with
    /// `weaveLarge`, at the large detent alone.
    private struct WeaveSheet: Identifiable {
        let large: Bool
        var id: Bool { large }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(exchanges.reversed().enumerated()), id: \.element.id) { index, exchange in
                        if index > 0 {
                            Rectangle()
                                .fill(Color.secondary.opacity({{n:echoes.ruleOpacity}}))
                                .frame(width: {{n:echoes.rule#0}}, height: {{n:echoes.rule#1}})
                                .padding(.bottom, {{n:echoes.ruleGap}})
                        }
                        block(exchange)
                            .padding(.bottom, {{n:echoes.block}})
                            .id(exchange.id)
                    }
                }
                .padding(.top, {{n:echoes.top}})
                .padding(.horizontal, {{n:echoes.side}})
                .padding(.bottom, {{n:echoes.bottom}})
            }
            .scrollIndicators(.hidden)
            .modifier(ConverseInlineTitle())
            .toolbar {
                ConverseBarTitle(text: {{s:echoes.title}})
                if !readings.isEmpty {
                    ToolbarItem(placement: ConversePlatform.leading) {
                        Button {
                            ConversePlatform.tap()
                            weave = WeaveSheet(large: false)
                        } label: {
                            Image(systemName: {{y:weave}})
                                .font(.headline)
                                .foregroundStyle(ConverseLook.accent.gradient)
                                .padding(.horizontal, {{n:echoes.weavePadding}})
                        }
                        .accessibilityLabel({{s:echoes.weaveLabel}})
                    }
                }
                ToolbarItem(placement: ConversePlatform.trailing) {
                    ConverseCloseButton { dismiss() }
                }
            }
            .navigationDestination(for: ConverseRoute.self) { route in
                ConverseRouteView(route: route, exchanges: exchanges, documents: documents, close: { dismiss() })
            }
        }
        .tint(ConverseLook.accent)
        .sheet(item: $weave) { shown in
            ConverseWeave(readings: readings, entered: opensWeave, open: opensWeave ? weaveReading : nil)
                .presentationDetents(shown.large ? [.large] : [.medium, .large])
        }
        .task {
            guard opensWeave, !readings.isEmpty else { return }
            try? await Task.sleep(for: .seconds({{n:launch.nested}}))
            weave = WeaveSheet(large: weaveLarge)
        }
    }

    private func block(_ exchange: ConverseExchange) -> some View {
        VStack(alignment: .leading, spacing: {{n:echoes.replyGap}}) {
            Text(exchange.prompt)
                .font(ConverseLook.body2)
                .foregroundStyle(Color.primary.opacity({{n:ink.body2}}))
                .lineSpacing({{n:echoes.promptSpacing}})
                .contextMenu { copyButton(exchange.prompt) }
            if let reply = exchange.reply {
                NavigationLink(value: ConverseRoute.sources(exchange.id)) {
                    ConverseReplyText(text: reply, font: ConverseLook.note2, lineSpacing: {{n:echoes.replySpacing}},
                                      paragraphSpacing: {{n:echoes.paragraphs}}, kerning: 0, opacity: {{n:ink.note2}})
                        .contextMenu { copyButton(reply) }
                }
                .buttonStyle(.plain)
            } else {
                ConverseStillDots()
            }
        }
    }

    private func copyButton(_ text: String) -> some View {
        Button {
            ConversePlatform.copy(text)
        } label: {
            Label({{s:echoes.copy}}, systemImage: {{y:copy}})
        }
    }
}

extension ConverseTranscript where Documents == EmptyView {
    init(exchanges: [ConverseExchange], readings: [ConverseReading], opensWeave: Bool = false, weaveLarge: Bool = false, weaveReading: String? = nil) {
        self.init(exchanges: exchanges, readings: readings, documents: nil, opensWeave: opensWeave, weaveLarge: weaveLarge, weaveReading: weaveReading)
    }
}

/// Where a sheet's stack goes: an exchange's sources, one group's documents, or documents by their ids.
enum ConverseRoute: Hashable {
    /// The sources of the exchange with this id.
    case sources(String)
    /// The documents of a group, by the exchange's id and the group's.
    case group(String, String)
    /// Documents by their ids.
    case documents([String])
}

/// A route, drawn: what a sheet's stack pushes. Documents are the app's view when it gives one, else a list of their
/// ids and texts.
struct ConverseRouteView<Documents: View>: View {
    let route: ConverseRoute
    let exchanges: [ConverseExchange]
    let documents: (([String]) -> Documents)?
    let close: () -> Void

    var body: some View {
        switch route {
        case .sources(let id):
            ConverseSourcesList(exchange: exchanges.first { $0.id == id }, close: close)
        case .group(let id, let group):
            ConverseSourceDetail(documents: Self.group(group, in: exchanges.first { $0.id == id })?.documents ?? [], close: close)
        case .documents(let ids):
            if let documents {
                documents(ids)
            } else {
                ConverseDocumentPage(documents: Self.documents(ids, in: exchanges), close: close)
            }
        }
    }

    static func group(_ id: String, in exchange: ConverseExchange?) -> ConverseGroup? {
        exchange?.owners.flatMap(\.shownGroups).first { $0.id == id }
    }

    /// The documents with these ids, from the exchanges' owners; an id none of them holds is shown by its id alone.
    static func documents(_ ids: [String], in exchanges: [ConverseExchange]) -> [ConverseDocument] {
        let known = exchanges.flatMap(\.owners).flatMap { $0.documents + $0.groups.flatMap(\.documents) }
        return ids.map { id in known.first { $0.id == id } ?? ConverseDocument(id: id) }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ConverseTranscript(exchanges: ConverseSamples.exchanges, readings: ConverseSamples.readings)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
}
"""#
}
