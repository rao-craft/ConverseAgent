extension Template {
    static let platform = #"""
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// What differs between the iPhone and the Mac, in one place: the tap a control gives, the clipboard, where bar
/// buttons go.
enum ConversePlatform {
    /// A light tap, on every tap that acts.
    @MainActor static func tap() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    /// `text` on the clipboard.
    @MainActor static func copy(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    /// The bar's leading end.
    static var leading: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .navigation
        #endif
    }

    /// The bar's trailing end.
    static var trailing: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .primaryAction
        #endif
    }
}

/// A title centred in the bar, in the title font and its ink: the stage's and every sheet's.
struct ConverseBarTitle: ToolbarContent {
    let text: String

    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(text)
                .font(ConverseLook.title)
                .foregroundStyle(Color.primary.opacity({{n:ink.title}}))
        }
    }
}

/// A sheet's close button: the close symbol in the accent, hierarchical, with a light tap. A list sheet's is a size
/// larger; the weave's gives no tap.
struct ConverseCloseButton: View {
    var large = false
    var tapped = true
    let action: () -> Void

    var body: some View {
        Button {
            if tapped { ConversePlatform.tap() }
            action()
        } label: {
            Label({{s:close}}, systemImage: {{y:close}})
                .labelStyle(.iconOnly)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(ConverseLook.accent)
                .imageScale(large ? .large : .medium)
        }
    }
}

/// A bar that shows its title inline, where the platform has one.
struct ConverseInlineTitle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.navigationBarTitleDisplayMode(.inline)
        #else
        content
        #endif
    }
}

/// The bar with no background of its own, while an exchange is on the stage.
struct ConverseClearBar: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.toolbarBackground(.hidden, for: .navigationBar)
        #else
        content
        #endif
    }
}

/// A list in inset groups on the iPhone, inset on the Mac.
struct ConverseGroupedList: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content.listStyle(.insetGrouped)
        #else
        content.listStyle(.inset)
        #endif
    }
}

#Preview {
    NavigationStack {
        Text({{s:sources.emptyTitle}})
            .modifier(ConverseInlineTitle())
            .toolbar {
                ConverseBarTitle(text: {{s:sources.title}})
                ToolbarItem(placement: ConversePlatform.trailing) {
                    ConverseCloseButton(large: true) {}
                }
            }
    }
}
"""#
}
