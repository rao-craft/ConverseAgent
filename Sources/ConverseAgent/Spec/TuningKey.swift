//  WHAT: Every number the views are drawn and moved by, as a tuning key: its group, its name, what it holds and its
//        default. A call sets any of them with `tuning` lines; the rest keep their defaults, which are Seer's.
//  PIN:  A NUMBER IS WRITTEN AS THE CALL WROTE IT. `0.20` lands as `.opacity(0.20)` and `1.0` as
//        `.easeIn(duration: 1.0)`, in the form a person writes SwiftUI, so what the code says is what was asked.

import Foundation

struct TuningKey: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        /// One number; `signed` when it may be below zero.
        case number(signed: Bool)
        /// One whole number, zero or more.
        case count
        /// Exactly this many numbers, read as one value: `0.16 1 0.3 1`.
        case numbers(Int, signed: Bool)
        /// One colour: `rgb(70, 50, 110)`, `(0.38, 0.55, 0.38)` or `#AE9060`.
        case color
        /// One or more colours, in order.
        case colors

        var inWords: String {
            switch self {
            case .number(let signed): return signed ? "a number" : "a number, zero or more"
            case .count: return "a whole number"
            case .numbers(let count, _): return "\(count) numbers"
            case .color: return "a colour (rgb(r, g, b) from 0 to 255, (r, g, b) from 0 to 1, or #RRGGBB)"
            case .colors: return "colours (rgb(r, g, b), (r, g, b) or #RRGGBB, one after another)"
            }
        }
    }

    /// `reveal.base`, or `palette` for a key that is its own group.
    let name: String
    let kind: Kind
    /// The default, as a line would write it.
    let fallback: String
    /// What it sets, in a few words.
    let doc: String

    var group: String { name.split(separator: ".").first.map(String.init) ?? name }
    var word: String { name.split(separator: ".").dropFirst().first.map(String.init) ?? name }

    static func key(_ name: String, _ kind: Kind, _ fallback: String, _ doc: String) -> TuningKey {
        TuningKey(name: name, kind: kind, fallback: fallback, doc: doc)
    }

    static let number = Kind.number(signed: false)
    static let signed = Kind.number(signed: true)

    /// The groups, in the order the reference lists them.
    static var groups: [String] {
        var seen: [String] = []
        for key in all where !seen.contains(key.group) { seen.append(key.group) }
        return seen
    }

    static func named(_ name: String) -> TuningKey? { all.first { $0.name.lowercased() == name.lowercased() } }

    static func keys(in group: String) -> [TuningKey] { all.filter { $0.group.lowercased() == group.lowercased() } }

    static let all: [TuningKey] = [
        // The reveal: a reply typed out character by character.
        key("reveal.base", number, "15", "milliseconds each character waits before the next"),
        key("reveal.jitter", number, "10", "random milliseconds added to each wait, from 0 to this"),
        key("reveal.wait", number, "1.2", "seconds from the send before the reply starts to show"),
        key("reveal.cursor", number, "0.55", "seconds between the cursor's blinks"),
        key("reveal.cursorOpacity", number, "0.4", "the cursor's opacity"),
        // The exchange that leaves as the next arrives.
        key("leave.duration", number, "1.0", "seconds the leaving exchange eases out over"),
        key("leave.rise", number, "30", "points it rises as it leaves"),
        key("leave.scale", number, "0.96", "the scale it shrinks to"),
        key("leave.blur", number, "10", "the blur it dissolves into"),
        key("leave.remove", number, "1.1", "seconds from the send until it is removed"),
        // The exchange that arrives.
        key("arrive.curve", .numbers(4, signed: true), "0.16 1 0.3 1", "the timing curve's control points it comes to rest by"),
        key("arrive.duration", number, "0.9", "seconds it takes to come to rest"),
        key("arrive.drop", number, "16", "points below its place it starts from"),
        key("arrive.blur", number, "6", "the blur it starts from"),
        // The strokes over a reply's phrases.
        key("stroke.opacity", number, "0.20", "the opacity a stroke is filled at"),
        key("stroke.fade", number, "0.7", "seconds a stroke fades in over"),
        key("stroke.stagger", number, "0.15", "seconds between the strokes of a paragraph"),
        key("stroke.width", number, "12", "points a stroke is wider than its words"),
        key("stroke.height", number, "8", "points a stroke is taller than its words"),
        key("stroke.rows", number, "7", "points between the reply's lines once it is brushed"),
        key("stroke.tilt", number, "0.8", "how far a stroke's edges tilt from end to end, at most"),
        key("stroke.pinch", .numbers(2, signed: false), "0.22 0.143", "how much the left and the right tips are pinched, of the height"),
        key("stroke.top", .numbers(2, signed: true), "-0.25 0.10", "how far the top edge's points move, of the height (up is below zero)"),
        key("stroke.bottom", .numbers(2, signed: true), "-0.10 0.25", "how far the bottom edge's points move, of the height"),
        key("palette", .colors, "(0.38, 0.55, 0.38) (0.56, 0.49, 0.32) (0.94, 0.56, 0.68) (0.22, 0.44, 0.65) (0.65, 0.40, 0.55)",
            "the owners' colours, in order"),
        // The orb behind the stage.
        key("orb.size", number, "500", "the orb's width"),
        key("orb.radius", number, "250", "the radius its gradient fades out at"),
        key("orb.inner", .color, "rgb(70, 50, 110)", "the colour at its centre"),
        key("orb.opacity", number, "0.045", "the opacity at its centre"),
        key("orb.outer", .color, "rgb(40, 60, 90)", "the colour halfway out"),
        key("orb.outerOpacity", number, "0.02", "the opacity halfway out"),
        key("orb.drift", number, "30", "seconds it drifts one way"),
        key("orb.offset", number, "5", "points it drifts each way"),
        key("orb.scales", .numbers(2, signed: false), "0.98 1.02", "the scales it drifts between"),
        key("orb.center", number, "0.45", "where its centre rests, of the screen's height"),
        // The dot of an empty stage.
        key("idle.size", number, "4", "the dot's width at rest"),
        key("idle.grow", number, "8", "its width at the top of a breath"),
        key("idle.opacity", number, "0.12", "its opacity at rest"),
        key("idle.glow", number, "0.42", "its opacity at the top of a breath"),
        key("idle.breath", number, "4", "seconds a breath takes"),
        key("idle.fade", number, "0.4", "seconds it fades out and back over"),
        // The dots while a reply is thought of.
        key("dots.size", number, "2.5", "each dot's width"),
        key("dots.spacing", number, "7", "points between the dots"),
        key("dots.height", number, "24", "the row's height"),
        key("dots.inset", number, "4", "the row's inset"),
        key("dots.low", number, "0.2", "a dot's opacity at its faintest"),
        key("dots.high", number, "0.55", "a dot's opacity at its brightest"),
        key("dots.duration", number, "2", "seconds from faintest to brightest"),
        key("dots.delay", number, "0.35", "seconds each dot waits after the one before"),
        // The stage and its exchange column.
        key("stage.top", number, "8", "the stage's padding at the top"),
        key("stage.side", number, "24", "the stage's padding at the sides"),
        key("stage.bottom", number, "24", "the stage's padding above the pill"),
        key("column.width", number, "460", "the exchange column's widest"),
        key("column.gap", number, "18", "points between the prompt and the reply"),
        key("column.paragraphs", number, "16", "points between a reply's paragraphs"),
        key("column.promptSpacing", number, "5", "the prompt's line spacing"),
        key("column.promptKerning", number, "0.2", "the prompt's kerning"),
        key("column.replySpacing", number, "7", "the reply's line spacing"),
        key("column.replyKerning", number, "0.3", "the reply's kerning"),
        key("column.code", number, "15", "the size of code in a reply"),
        // The ink each type role is set in: the primary colour at these opacities.
        key("ink.title", number, "0.75", "titles' opacity"),
        key("ink.body", number, "0.75", "the stage's prompt and a weave row's word"),
        key("ink.body2", number, "0.75", "the transcript's prompts and a group's name"),
        key("ink.note", number, "0.6", "the stage's reply and the empty sources line"),
        key("ink.note2", number, "0.6", "the transcript's replies and a group's summary"),
        // The input pill.
        key("pill.radius", number, "24", "the pill's corner radius"),
        key("pill.inset", number, "16", "points from the screen's sides and bottom"),
        key("pill.vertical", number, "14", "its padding above and below"),
        key("pill.horizontal", number, "16", "its padding at the sides"),
        key("pill.gap", number, "12", "points between the field and the send button"),
        key("pill.fieldBottom", number, "2", "the field's padding below its last line"),
        key("pill.micGap", number, "14", "points between the send arrow and the microphone, when the page gives `listen`"),
        key("pill.mic", number, "16", "the microphone's square"),
        key("pill.listenScale", number, "1.1", "the microphone's scale while it listens"),
        key("pill.micEase", number, "0.2", "seconds the microphone eases between its states"),
        key("pill.font", number, "19", "the field's font size"),
        key("pill.lines", .count, "5", "the lines the field grows to before it scrolls"),
        key("pill.text", number, "0.8", "the field's text opacity"),
        key("pill.hint", number, "0.3", "the placeholder's opacity"),
        key("pill.caret", number, "0.3", "the caret's opacity"),
        key("pill.send", number, "14", "the send arrow's size"),
        key("pill.ready", number, "0.75", "the arrow's opacity when it can send"),
        key("pill.idle", number, "0.3", "its opacity when it cannot"),
        key("pill.ease", number, "0.25", "seconds the arrow eases between them"),
        key("pill.shadow", .numbers(2, signed: false), "2 4", "the pill's shadow radius and drop"),
        // The glass bands at the screen's edges.
        key("edge.height", number, "150", "each band's height"),
        key("edge.tint", number, "0.07", "the white tint at the screen's edge"),
        key("edge.fade", number, "0.2", "seconds the top band fades in and out over"),
        // The transcript.
        key("echoes.top", number, "12", "the list's padding at the top"),
        key("echoes.side", number, "24", "its padding at the sides"),
        key("echoes.bottom", number, "40", "its padding at the bottom"),
        key("echoes.block", number, "24", "points below each exchange"),
        key("echoes.rule", .numbers(2, signed: false), "16 1", "the rule's width and height"),
        key("echoes.ruleOpacity", number, "0.5", "the rule's opacity"),
        key("echoes.ruleGap", number, "32", "points below the rule"),
        key("echoes.promptSpacing", number, "4", "a prompt's line spacing"),
        key("echoes.replyGap", number, "16", "points between a prompt and its reply"),
        key("echoes.replySpacing", number, "6", "a reply's line spacing"),
        key("echoes.paragraphs", number, "16", "points between a reply's paragraphs"),
        key("echoes.dot", number, "2", "each still dot's width while a reply is thought of"),
        key("echoes.dotSpacing", number, "4", "points between the still dots"),
        key("echoes.dotOpacity", number, "0.4", "the still dots' opacity"),
        key("echoes.weavePadding", signed, "-2", "the weave button's padding at its sides"),
        // The sources sheet and its detail.
        key("sources.cut", .count, "27", "the characters a document's row shows before \"...\""),
        key("sources.indicator", number, "36", "the round indicator's width"),
        key("sources.wash", number, "0.25", "the background's wash over an indicator's face"),
        key("sources.symbol", number, "0.8", "an indicator symbol's opacity"),
        key("sources.ring", number, "1", "an indicator's ring"),
        key("sources.shadow", .numbers(2, signed: false), "2 2", "an indicator's shadow radius and drop"),
        key("sources.fade", number, "0.8", "where an indicator face's gradient ends, of its colour"),
        key("sources.gap", number, "12", "points between an indicator and its words"),
        key("sources.ownerGap", number, "16", "points between an indicator and an owner's name in a row of its own"),
        key("sources.rowPadding", number, "4", "a group row's padding above and below"),
        key("sources.stack", number, "4", "points between a group row's lines"),
        key("sources.ownerFont", number, "14", "an owner's name size"),
        key("sources.royaltyFont", number, "12", "an owner's royalty size"),
        key("sources.countFont", number, "12", "a group's document count size"),
        key("sources.countInk", number, "0.35", "the count's opacity"),
        key("sources.chip", number, "11", "a tag chip's font size"),
        key("sources.chipPadding", .numbers(2, signed: false), "8 2", "a chip's padding across and down"),
        key("sources.chipInk", number, "0.8", "a chip's text opacity"),
        key("sources.chipFill", number, "0.10", "a chip's fill opacity"),
        key("sources.chipBorder", number, "0.2", "a chip's border opacity"),
        key("sources.emptyIcon", number, "50", "the empty state's symbol size"),
        key("sources.emptyPadding", number, "42", "the empty state's side padding"),
        key("sources.emptyTitleGap", number, "3", "points below the empty state's title"),
        key("sources.emptyBottom", number, "15", "points below the empty state's line"),
        key("detail.margin", number, "4", "the detail list's vertical content margin"),
        key("detail.gap", number, "16", "points between an indicator and a document's id"),
        // The weave.
        key("weave.height", number, "336", "the canvas's height"),
        key("weave.speed", number, "0.4", "the canvas's time, per second"),
        key("weave.frames", number, "60", "the canvas's frames a second, at most"),
        key("weave.bleed", number, "8", "points the canvas runs past each side"),
        key("weave.canvasTop", number, "4", "the canvas's padding above"),
        key("weave.canvasBottom", number, "12", "the canvas's padding below"),
        key("weave.warp", .count, "16", "the warp's lines across"),
        key("weave.warpTop", number, "75", "points above the centre the warp starts"),
        key("weave.warpSpacing", number, "10", "points between warp lines"),
        key("weave.warpAmplitude", number, "3", "how far a warp line waves"),
        key("weave.warpFrequency", number, "0.006", "a warp line's wave, per point across"),
        key("weave.warpDrift", number, "0.1", "a warp line's wave, per unit of time"),
        key("weave.warpPhase", number, "0.45", "each warp line's phase after the one before"),
        key("weave.warpColor", .color, "rgb(160, 140, 110)", "the warp's colour"),
        key("weave.warpOpacity", number, "0.06", "the warp's opacity"),
        key("weave.warpWidth", number, "0.6", "a warp line's width"),
        key("weave.warpStep", number, "2", "points between a warp line's samples"),
        key("weave.warpSwell", number, "2", "how far a warp line's second, slower wave moves it"),
        key("weave.warpSwellFrequency", number, "0.0025", "that wave, per point across"),
        key("weave.warpSwellDrift", number, "0.05", "that wave, per unit of time"),
        key("weave.warpFlicker", number, "0.015", "how far a warp line's opacity wavers"),
        key("weave.warpFlickerRate", number, "0.07", "its wavering, per unit of time"),
        key("weave.warpFlickerPhase", number, "0.6", "each warp line's wavering after the one before"),
        key("weave.weft", .count, "7", "the weft's lines down"),
        key("weave.weftSpacing", number, "11", "points between weft lines"),
        key("weave.weftAmplitude", number, "37", "how far a weft line waves"),
        key("weave.weftBase", number, "0.5", "the first weft line's share of that"),
        key("weave.weftGrowth", number, "0.06", "the share each weft line adds"),
        key("weave.weftFrequency", number, "0.0118", "a weft line's wave, per point down"),
        key("weave.weftDrift", number, "0.54", "a weft line's wave, per unit of time"),
        key("weave.weftPhase", number, "1.1", "each weft line's phase after the one before"),
        key("weave.weftColor", .color, "rgb(130, 105, 60)", "the weft's colour"),
        key("weave.weftCenter", .numbers(2, signed: false), "0.5 1.5", "the middle weft line's opacity and width"),
        key("weave.weftOpacity", .numbers(2, signed: false), "0.05 0.36", "the other weft lines' opacity: at the edge, and added toward the middle"),
        key("weave.weftWidth", number, "0.7", "the other weft lines' width"),
        key("weave.weftStep", number, "1.5", "points between a weft line's samples"),
        key("weave.weftEcho", number, "0.1", "a weft line's second wave, of its swing"),
        key("weave.weftEchoFrequency", number, "2.2", "that wave's frequency, of the first's"),
        key("weave.weftEchoDrift", number, "0.55", "that wave's phase, of the first's"),
        key("weave.weftSway", number, "5", "how far the whole weft sways"),
        key("weave.weftSwayFrequency", number, "0.004", "its sway, per point down"),
        key("weave.weftSwayDrift", number, "0.07", "its sway, per unit of time"),
        key("weave.glows", .count, "8", "the glows"),
        key("weave.glowReach", number, "32", "how far a glow sways"),
        key("weave.glowFrequency", number, "0.22", "a glow's sway, per unit of time"),
        key("weave.glowCurve", number, "0.012", "a glow's sway, per point down"),
        key("weave.glowBreath", number, "0.45", "a glow's breathing, per unit of time"),
        key("weave.glowPhase", number, "1.9", "each glow's phase after the one before"),
        key("weave.glowTop", number, "55", "points above the centre the glows start"),
        key("weave.glowSpacing", number, "15", "points between glows"),
        key("weave.glowColor", .color, "rgb(150, 125, 75)", "a glow's colour"),
        key("weave.glowSize", .numbers(2, signed: false), "7 13", "a glow's radius, smallest and largest"),
        key("weave.glowOpacity", .numbers(2, signed: false), "0.03 0.06", "a glow's opacity, faintest and brightest"),
        key("weave.words", number, "18", "the words' font size"),
        key("weave.tracking", number, "0.8", "the words' tracking"),
        key("weave.wordsInk", number, "0.6", "the words' opacity"),
        key("weave.wordsTop", number, "16", "points above the words"),
        key("weave.wordsBottom", number, "8", "points below them"),
        key("weave.wordRise", number, "5", "points a word rises as it fades in"),
        key("weave.separatorSize", number, "13", "the separator's font size"),
        key("weave.separatorInk", number, "0.42", "the separator's opacity"),
        key("weave.separatorPadding", number, "4", "points at each side of a separator"),
        key("weave.separatorFade", number, "2.0", "seconds a separator fades in over"),
        key("weave.rule", .numbers(2, signed: false), "40 0.5", "the short rule under the words: width and height"),
        key("weave.ruleColor", .color, "rgb(140, 120, 85)", "the rule's colour"),
        key("weave.ruleOpacity", number, "0.18", "the rule's opacity"),
        key("weave.rulePadding", number, "8", "points above and below the rule"),
        key("weave.ruleFade", number, "2.5", "seconds the rule fades in over"),
        key("weave.inset", number, "28", "the rows' and the legend's inset from the sides"),
        key("weave.dot", number, "5", "a row's dot"),
        key("weave.dotGap", number, "14", "points between a row's dot and its word"),
        key("weave.rowPadding", number, "24", "a row's padding above and below"),
        key("weave.rowRise", number, "8", "points a row rises as it fades in"),
        key("weave.wordTracking", number, "0.4", "a row's word's tracking"),
        key("weave.reading", number, "16", "a reading's font size"),
        key("weave.readingInk", number, "0.62", "a reading's opacity"),
        key("weave.readingSpacing", number, "8", "a reading's line spacing"),
        key("weave.readingInset", number, "19", "a reading's inset, under its word"),
        key("weave.readingBottom", number, "20", "points below a reading"),
        key("weave.readingWidth", number, "360", "a reading's widest"),
        key("weave.readingIn", number, "0.6", "seconds a reading eases in over"),
        key("weave.readingOut", number, "0.3", "seconds it eases out over"),
        key("weave.inkLight", .color, "rgb(90, 72, 45)", "the words' ink in light mode"),
        key("weave.inkDark", .color, "rgb(214, 196, 164)", "the words' ink in dark mode"),
        key("weave.readingLight", .color, "rgb(75, 62, 40)", "a reading's ink in light mode"),
        key("weave.readingDark", .color, "rgb(214, 196, 164)", "a reading's ink in dark mode"),
        key("weave.dotOpen", .color, "rgb(130, 105, 60)", "the open row's dot"),
        key("weave.dotOpenOpacity", number, "0.5", "its opacity"),
        key("weave.dotClosed", .color, "rgb(155, 138, 108)", "a closed row's dot"),
        key("weave.dotClosedOpacity", number, "0.22", "its opacity"),
        key("weave.dotBreath", number, "1.75", "seconds an open dot's breath takes"),
        key("weave.dotBreaths", .numbers(2, signed: false), "0.25 0.6", "the opacities it breathes between"),
        key("weave.divider", .color, "rgb(150, 132, 105)", "the hairline between rows and over the legend"),
        key("weave.dividerOpacity", number, "0.1", "its opacity"),
        key("weave.dividerHeight", number, "0.5", "its height"),
        key("weave.endDot", number, "4", "the breathing dot at the foot of the page"),
        key("weave.endTop", number, "48", "points above it"),
        key("weave.endBottom", number, "80", "points below it"),
        key("weave.endFade", number, "4.5", "seconds it fades in over"),
        key("weave.entrance", number, "0.4", "seconds after the sheet appears that its entrance begins"),
        key("weave.toggle", number, "0.4", "seconds a reading opens and closes over"),
        key("weave.canvasFade", number, "2.2", "seconds the canvas fades in over"),
        key("weave.wordFade", number, "1.8", "seconds each word fades in over"),
        key("weave.wordStagger", number, "0.4", "seconds between the words"),
        key("weave.rowFade", number, "1.2", "seconds each row fades in over"),
        key("weave.rowStart", number, "2.0", "seconds before the rows start"),
        // The legend under the weave's rows, its colours the same in light and dark.
        key("legend.top", number, "40", "points between the rows and the legend"),
        key("legend.spacing", number, "10", "points between the legend's lines, its hairline the first"),
        key("legend.ruleBottom", number, "4", "points under the hairline, beside that spacing"),
        key("legend.size", number, "11", "its font size"),
        key("legend.tracking", number, "2.5", "a quality's tracking"),
        key("legend.column", number, "90", "the width a quality takes before its indicators"),
        key("legend.quality", .color, "rgb(120, 100, 68)", "a quality's colour"),
        key("legend.qualityInk", number, "0.70", "its opacity"),
        key("legend.ink", .color, "rgb(155, 138, 108)", "the indicators' and the value's colour"),
        key("legend.inkOpacity", number, "0.60", "their opacity"),
        key("legend.fade", number, "3.0", "seconds the legend fades in over"),
        // Launch: how a destination opens.
        key("launch.nested", number, "0.6", "seconds before a sheet opened over another sheet at launch"),
    ]
}
