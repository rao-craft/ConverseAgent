extension Template {
    static let pill = #"""
import SwiftUI

/// The input: a field that grows a few lines and then scrolls, then a send arrow, in a pill of Liquid Glass; a
/// microphone after the arrow when the page gives `listen`. Return sends, as the arrow does; the arrow dims while there
/// is nothing to send or a reply is still coming.
struct ConversePill: View {
    @Binding var text: String
    let placeholder: String
    let canSend: Bool
    var focused: FocusState<Bool>.Binding
    let send: @MainActor () -> Void
    var listen: (@MainActor () -> Void)? = nil
    var listening = false

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            framed
                .glassEffect(in: RoundedRectangle(cornerRadius: {{n:pill.radius}}))
                .shadow(color: ConverseLook.cardShadow, radius: {{n:pill.shadow#0}}, x: 0, y: {{n:pill.shadow#1}})
        } else {
            framed
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: {{n:pill.radius}}))
                .shadow(color: ConverseLook.cardShadow, radius: {{n:pill.shadow#0}}, x: 0, y: {{n:pill.shadow#1}})
        }
    }

    private var framed: some View {
        VStack(spacing: 0) {
            row
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, {{n:pill.vertical}})
        .padding(.horizontal, {{n:pill.horizontal}})
    }

    private var row: some View {
        HStack(spacing: 0) {
            TextField(text: $text, axis: .vertical) {
                Text(placeholder)
                    .font(.system(size: {{n:pill.font}}, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.primary.opacity({{n:pill.hint}}))
            }
            .font(.system(size: {{n:pill.font}}, weight: .light, design: .serif))
            .foregroundStyle(Color.primary.opacity({{n:pill.text}}))
            .tint(Color.primary.opacity({{n:pill.caret}}))
            .focused(focused)
            .lineLimit(1...{{n:pill.lines}})
            .submitLabel(.return)
            .onSubmit { sendIfPossible() }
            .onChange(of: text) { _, newValue in
                // A field that grows takes return as a new line: here it sends.
                guard newValue.contains("\n") else { return }
                text = newValue.replacingOccurrences(of: "\n", with: "")
                sendIfPossible()
            }
            .padding(.bottom, {{n:pill.fieldBottom}})

            Button {
                sendIfPossible()
            } label: {
                Image(systemName: {{y:send}})
                    .font(.system(size: {{n:pill.send}}, weight: .light))
                    .foregroundStyle(Color.primary.opacity(canSend ? {{n:pill.ready}} : {{n:pill.idle}}))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: {{n:pill.ease}}), value: canSend)
            .accessibilityLabel({{s:stage.sendLabel}})
            .padding(.leading, {{n:pill.gap}})
            .padding(.trailing, listen == nil ? 0 : {{n:pill.micGap}})

            if let listen {
                Button {
                    listen()
                } label: {
                    Image(systemName: listening ? {{y:listening}} : {{y:listen}})
                        .font(.system(size: {{n:pill.send}}, weight: .light))
                        .foregroundStyle(Color.primary.opacity(listening ? {{n:pill.ready}} : {{n:pill.idle}}))
                        .scaleEffect(listening ? {{n:pill.listenScale}} : 1)
                }
                .frame(width: {{n:pill.mic}}, height: {{n:pill.mic}})
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: {{n:pill.micEase}}), value: listening)
                .accessibilityLabel({{s:stage.listenLabel}})
            }
        }
    }

    private func sendIfPossible() {
        guard canSend else { return }
        send()
    }
}

private struct ConversePillPreview: View {
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ConversePill(text: $text, placeholder: {{s:stage.placeholder}}, canSend: !text.isEmpty, focused: $focused, send: { text = "" })
            .padding()
    }
}

#Preview {
    ConversePillPreview()
}
"""#
}
