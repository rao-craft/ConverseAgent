extension Template {
    static let sources = #"""
import SwiftUI

/// Whose documents shaped a reply, as a sheet of its own: the person's library first, then each other owner's groups
/// of documents, with the share each earned. A group pushes its documents inside the sheet.
struct ConverseSources<Documents: View>: View {
    let exchange: ConverseExchange?
    let documents: (([String]) -> Documents)?

    @Environment(\.dismiss) private var dismiss
    @State private var path: [ConverseRoute]

    /// `opening` names a group (by name or id) whose documents are pushed already, as a launch opens it.
    init(exchange: ConverseExchange?, documents: (([String]) -> Documents)?, opening: String? = nil) {
        self.exchange = exchange
        self.documents = documents
        let group = opening.flatMap { wanted in
            exchange?.owners.flatMap(\.shownGroups).first { $0.name == wanted || $0.id == wanted }
        }
        if let exchange, let group {
            _path = State(initialValue: [.group(exchange.id, group.id)])
        } else {
            _path = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ConverseSourcesList(exchange: exchange, close: { dismiss() })
                .navigationDestination(for: ConverseRoute.self) { route in
                    ConverseRouteView(route: route, exchanges: exchange.map { [$0] } ?? [], documents: documents, close: { dismiss() })
                }
        }
        .tint(ConverseLook.accent)
    }
}

extension ConverseSources where Documents == EmptyView {
    init(exchange: ConverseExchange?, opening: String? = nil) {
        self.init(exchange: exchange, documents: nil, opening: opening)
    }
}

/// A reply's sources as a list: a Library section when the person's own documents shaped it, then a section an
/// owner; with no owners, a still empty state.
struct ConverseSourcesList: View {
    let exchange: ConverseExchange?
    let close: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let exchange, !exchange.owners.isEmpty {
                List {
                    if let mine = exchange.owners.first(where: \.mine), !mine.shownDocuments.isEmpty {
                        Section {
                            ForEach(mine.shownDocuments) { document in
                                NavigationLink(value: ConverseRoute.documents([document.id])) {
                                    ConverseDocumentRow(document: document)
                                }
                            }
                        } header: {
                            HStack {
                                Text({{s:sources.library}})
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                Text({{s:sources.royalty|mine.royalty}})
                                    .font(.subheadline)
                            }
                            .textCase(nil)
                        }
                    }
                    ForEach(exchange.owners.filter { !$0.mine }) { owner in
                        Section {
                            if owner.groups.isEmpty {
                                NavigationLink(value: ConverseRoute.group(exchange.id, owner.id)) {
                                    ConverseOwnerRow(owner: owner)
                                }
                            } else {
                                ForEach(owner.groups) { group in
                                    NavigationLink(value: ConverseRoute.group(exchange.id, group.id)) {
                                        ConverseGroupRow(group: group)
                                    }
                                }
                            }
                        } header: {
                            ConverseOwnerHeader(owner: owner)
                        }
                    }
                }
                .modifier(ConverseGroupedList())
            } else {
                ConverseNoSources()
            }
        }
        .modifier(ConverseInlineTitle())
        .toolbar {
            ConverseBarTitle(text: {{s:sources.title}})
            ToolbarItem(placement: ConversePlatform.trailing) {
                ConverseCloseButton(large: true, action: close)
            }
        }
    }
}

/// A row of the person's library: the document's indicator, the start of its text in one line, its share below.
struct ConverseDocumentRow: View {
    let document: ConverseDocument

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: {{n:sources.gap}}) {
                ConverseIndicator(symbol: {{y:document}}, offset: CGSize(width: 0.5, height: 0))
                VStack(alignment: .leading) {
                    Text(title)
                        .lineLimit(1)
                        .foregroundStyle(Color.primary)
                        .fontWeight(.medium)
                    VStack(alignment: .leading) {
                        Text({{s:sources.influence|document.influence}})
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                    }
                }
            }
        }
    }

    /// The text's first characters, then the cut mark; the id when it has no text.
    private var title: String {
        let text = document.text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return document.id }
        guard text.count > {{n:sources.cut}} else { return text }
        return String(text.prefix({{n:sources.cut}})) + {{s:sources.more}}
    }
}

/// An owner's header: their indicator, their name, and trailing, their share of the reply.
struct ConverseOwnerHeader: View {
    let owner: ConverseOwner

    var body: some View {
        HStack(spacing: {{n:sources.gap}}) {
            ConverseIndicator(symbol: {{y:person}}, offset: CGSize(width: 0, height: -1))
            Text(owner.name.isEmpty ? "\u{2014}" : owner.name)
                .font(.system(size: {{n:sources.ownerFont}}, weight: .medium, design: .serif))
                .foregroundStyle(Color.primary)
            Spacer()
            Text({{s:sources.royalty|owner.royalty}})
                .font(.system(size: {{n:sources.royaltyFont}}, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }
}

/// An owner whose documents are in no group: one row of their own, pushing all of them.
struct ConverseOwnerRow: View {
    let owner: ConverseOwner

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: {{n:sources.ownerGap}}) {
                ConverseIndicator(symbol: {{y:person}}, offset: CGSize(width: 0, height: -1))
                VStack(alignment: .leading) {
                    Text(owner.name.isEmpty ? "\u{2014}" : owner.name)
                        .lineLimit(1)
                        .foregroundStyle(Color.primary)
                        .fontWeight(.medium)
                    VStack(alignment: .leading) {
                        Text({{s:sources.royalty|owner.royalty}})
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

/// A group of an owner's documents: its name, what it holds, its tags, and trailing, how many documents.
struct ConverseGroupRow: View {
    let group: ConverseGroup

    var body: some View {
        HStack(spacing: {{n:sources.gap}}) {
            VStack(alignment: .leading, spacing: {{n:sources.stack}}) {
                Text(group.name)
                    .font(ConverseLook.body2)
                    .foregroundStyle(Color.primary.opacity({{n:ink.body2}}))
                    .lineLimit(1)
                if !group.summary.isEmpty {
                    Text(group.summary)
                        .font(ConverseLook.note2)
                        .foregroundStyle(Color.primary.opacity({{n:ink.note2}}))
                        .lineLimit(2)
                }
                if !group.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: {{n:sources.stack}}) {
                            ForEach(group.tags, id: \.self) { tag in
                                ConverseChip(text: tag)
                            }
                        }
                    }
                }
            }
            Spacer()
            Text(group.documents.count == 1 ? {{s:sources.doc}} : {{s:sources.docs|group.documents.count}})
                .font(.system(size: {{n:sources.countFont}}, weight: .light, design: .serif))
                .foregroundStyle(Color.primary.opacity({{n:sources.countInk}}))
        }
        .padding(.vertical, {{n:sources.rowPadding}})
    }
}

/// A tag, as a small capsule in the accent.
struct ConverseChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: {{n:sources.chip}}, weight: .light, design: .serif))
            .padding(.horizontal, {{n:sources.chipPadding#0}})
            .padding(.vertical, {{n:sources.chipPadding#1}})
            .background(ConverseLook.accent.opacity({{n:sources.chipFill}}))
            .foregroundStyle(ConverseLook.accent.opacity({{n:sources.chipInk}}))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(ConverseLook.accent.opacity({{n:sources.chipBorder}}), lineWidth: 1))
    }
}

/// No one's documents shaped the reply.
struct ConverseNoSources: View {
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: {{y:empty}})
                .foregroundStyle(.secondary)
                .font(.system(size: {{n:sources.emptyIcon}}))
                .padding(.bottom)
            Text({{s:sources.emptyTitle}})
                .font(ConverseLook.title)
                .bold()
                .foregroundStyle(Color.primary.opacity({{n:ink.title}}))
                .padding(.bottom, {{n:sources.emptyTitleGap}})
            Text({{s:sources.emptyText}})
                .font(ConverseLook.note)
                .italic()
                .foregroundStyle(Color.primary.opacity({{n:ink.note}}))
                .multilineTextAlignment(.center)
                .padding(.horizontal, {{n:sources.emptyPadding}})
                .padding(.bottom, {{n:sources.emptyBottom}})
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ConverseSources(exchange: ConverseSamples.exchanges.first)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.regularMaterial)
        }
}
"""#

    static let indicator = #"""
import SwiftUI

/// The round badge before a document or an owner: a soft face with a faint ring and a small shadow, the symbol in the
/// middle. `washed` lays the background's wash over the face, as a list's rows have it.
struct ConverseIndicator: View {
    let symbol: String
    var washed = true
    var offset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(washed ? ConverseLook.background.opacity({{n:sources.wash}}) : Color.clear)
            .frame(width: {{n:sources.indicator}}, height: {{n:sources.indicator}})
            .overlay {
                Image(systemName: symbol)
                    .foregroundStyle(Color.primary.opacity({{n:sources.symbol}}).gradient)
                    .offset(offset)
            }
            .background(
                LinearGradient(colors: [ConverseLook.card, ConverseLook.card.opacity({{n:sources.fade}})],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        Circle().strokeBorder(.quaternary, lineWidth: {{n:sources.ring}})
                    }
            )
            .clipShape(Circle())
            .shadow(color: ConverseLook.buttonShadow, radius: {{n:sources.shadow#0}}, x: 0, y: {{n:sources.shadow#1}})
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        ConverseIndicator(symbol: {{y:document}}, offset: CGSize(width: 0.5, height: 0))
        ConverseIndicator(symbol: {{y:person}}, offset: CGSize(width: 0, height: -1))
        ConverseIndicator(symbol: {{y:document}}, washed: false)
    }
    .padding()
}
"""#

    static let sourceDetail = #"""
import SwiftUI

/// One group's documents, pushed in the sources sheet: each document's indicator, its id, and its share.
struct ConverseSourceDetail: View {
    let documents: [ConverseDocument]
    let close: () -> Void

    var body: some View {
        VStack {
            List {
                ForEach(documents) { document in
                    NavigationLink(value: ConverseRoute.documents([document.id])) {
                        VStack(alignment: .leading) {
                            HStack(spacing: {{n:detail.gap}}) {
                                ConverseIndicator(symbol: {{y:document}}, washed: false, offset: CGSize(width: 0.5, height: 0))
                                VStack(alignment: .leading) {
                                    Text(document.id)
                                        .lineLimit(1)
                                        .foregroundStyle(Color.primary)
                                        .fontWeight(.medium)
                                    Text({{s:sources.influence|document.influence}})
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
            .modifier(ConverseGroupedList())
            .contentMargins(.vertical, {{n:detail.margin}}, for: .scrollContent)
        }
        .modifier(ConverseInlineTitle())
        .toolbar {
            ConverseBarTitle(text: {{s:detail.title}})
            ToolbarItem(placement: ConversePlatform.trailing) {
                ConverseCloseButton(large: true, action: close)
            }
        }
    }
}

/// Documents by their ids, when the app shows none of its own: each one's id over its text.
struct ConverseDocumentPage: View {
    let documents: [ConverseDocument]
    let close: () -> Void

    var body: some View {
        List(documents) { document in
            VStack(alignment: .leading, spacing: {{n:sources.stack}}) {
                Text(document.id)
                    .lineLimit(1)
                    .foregroundStyle(Color.primary)
                    .fontWeight(.medium)
                if !document.text.isEmpty {
                    Text(document.text)
                        .font(ConverseLook.note2)
                        .foregroundStyle(Color.primary.opacity({{n:ink.note2}}))
                }
            }
            .padding(.vertical, {{n:sources.rowPadding}})
        }
        .modifier(ConverseGroupedList())
        .modifier(ConverseInlineTitle())
        .toolbar {
            ConverseBarTitle(text: documents.count == 1 ? documents[0].id : {{s:detail.title}})
            ToolbarItem(placement: ConversePlatform.trailing) {
                ConverseCloseButton(large: true, action: close)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConverseSourceDetail(documents: ConverseSamples.exchanges.first?.owners.last?.groups.first?.documents ?? [], close: {})
    }
}
"""#
}
