//  WHAT: Every file the kit writes from a template, and the views each holds. A call writes all of them: the stage
//        opens the transcript, the sources and the weave itself, so no part stands without the others.
//  PIN:  A FILE IS NAMED BY ITS PART WITH THE CALL'S PREFIX: `Stage` is `ConverseStage.swift`, or `VoidStage.swift`
//        with `prefix: Void`; every type the kit declares starts with the prefix, so one rename covers them all.

import Foundation

struct KitPart: Sendable {
    /// The file's name after the prefix: `Stage` is `ConverseStage.swift`.
    let name: String
    /// The views it declares, after the prefix, the one a page calls first; empty for a file of values or helpers.
    let views: [String]
    let template: String

    init(_ name: String, views: [String] = [], _ template: String) {
        self.name = name; self.views = views; self.template = template
    }
}

enum KitCatalog {
    /// The views a page calls: the stage first (it opens the others), then the sheets an app may show on its own.
    static let roots = ["Stage", "Transcript", "Sources", "SourceDetail", "Weave"]

    /// Every template part, in the order the stage is built from them: values and helpers first, the stage last.
    static let parts: [KitPart] = [
        KitPart("Values", Template.values),
        KitPart("Platform", views: ["CloseButton"], Template.platform),
        KitPart("Orb", views: ["Orb"], Template.orb),
        KitPart("Dots", views: ["IdleDot", "ThinkingDots", "StillDots"], Template.dots),
        KitPart("GlassEdge", views: ["GlassEdge"], Template.glassEdge),
        KitPart("Pill", views: ["Pill"], Template.pill),
        KitPart("ReplyText", views: ["ReplyText"], Template.replyText),
        KitPart("Stroke", Template.stroke),
        KitPart("FlowLayout", Template.flowLayout),
        KitPart("BrushedReply", views: ["BrushedReply", "BrushedParagraph", "StrokeMarkView"], Template.brushedReply),
        KitPart("ExchangeView", views: ["ExchangeView"], Template.exchangeView),
        KitPart("Indicator", views: ["Indicator"], Template.indicator),
        KitPart("Sources", views: ["Sources", "SourcesList", "DocumentRow", "OwnerHeader", "OwnerRow", "GroupRow", "Chip", "NoSources"],
                Template.sources),
        KitPart("SourceDetail", views: ["SourceDetail", "DocumentPage"], Template.sourceDetail),
        KitPart("WeaveCanvas", views: ["WeaveCanvas"], Template.weaveCanvas),
        KitPart("Weave", views: ["Weave", "ReadingRow", "BreathingDot"], Template.weave),
        KitPart("Transcript", views: ["Transcript", "RouteView"], Template.transcript),
        KitPart("Stage", views: ["Stage", "StageExchange"], Template.stage),
        KitPart("Samples", Template.samples),
    ]

    /// The files written by an emitter rather than a template, after the prefix.
    static let emitted = ["Look", "Launch", "Readings"]

    /// Every view the kit declares, after the prefix, roots first.
    static var views: [String] {
        var all = roots
        for part in parts { for view in part.views where !all.contains(view) { all.append(view) } }
        return all
    }
}
