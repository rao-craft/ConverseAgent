# Testing ConverseAgent

How `converse` is tested: its own suite, and a gated build of real output. Prompts run through
[Craft](https://github.com/riteshpakala/Craft) will be logged here as they are run.

## The suite

```
swift test                                                 # the record, the lines, the templates, the files, the roster
CONVERSE_BUILD=1 swift test --filter ConverseBuildTests    # the output built and drawn for real (gated, about a minute)
CONVERSE_EXAMPLES=1 swift test --filter ShippedFileTests   # writes the schemas and the Seer answer again
```

- **`ConverseAgentTests`:** the record is found with nothing listed; the schema a model is shown; the guide teaches
  every line, every role's words, the stage's initializer and one call, with no Seer name to copy; a call through
  Granite's roster writes the files it names, in the call's folder or the host's; a refused call says every reason
  and writes nothing.
- **`ShippedFileTests`:** `Schema/converse.input.schema.json` is the record's fields as the model sees them; the
  answer schema names the kinds it makes and its own keys; `Schema/Converse.md` lists every field, role word, look
  role, string, symbol, tuning key and launch state with its default, and gives the initializers and the page body;
  `Schema/examples/seer.answer.json` is what the Seer call answers over an app whose types live in SeerKit.
- **`LineTests`:** every kind of line, accepted in each form a model writes and refused with its reason: mappings,
  tuning (a group, a key, a colour, a palette), strings (quotes kept, `{n}` where a number goes), symbols, look,
  launch states and readings word for word; a call with twelve problems across nine fields refused with all twelve
  at once; the same key in two lines refused.
- **`TemplateTests`:** every template renders with and without a title and fills from the defaults; every key is
  read by a template and every placeholder names a key; the views each file declares are the catalog's; the prefix
  reaches every name the kit declares; every role has its protocol and conversions; a `#Preview` in every file that
  draws, and a label on every icon-only control.
- **`ConverseEmitTests`:** the files and names the Seer call writes, with no Granite import and no stored global
  state; the conformance to SeerKit's `Owner`, word for word; the launch file; every `code` item of Seer's scorecard
  for the four areas; every string the spec quotes for the five screens; the same bytes on a second run; a prefix on
  every file and type, and a folder that keeps the prefix it holds; each path checked against the app's types, in
  their spelling, with a local package imported; the least call over the kit's own values; an empty title and an
  escaped word.
- **`ConverseBuildTests`** (gated): three apps in one package, each with the page body a host writes. Seer from its
  example call, its types in a SeerKit target of their own, Swift 6; the tutor example with the prefix `Tutor`,
  Swift 5; the least call, Swift 6. Built with `swift build` for the Mac with no warning in what the kit wrote; every
  root view and the stage's parts drawn offscreen from each app's own values (`CONVERSE_SHOTS=<folder>` keeps the
  pictures, `CONVERSE_KEEP=<folder>` the package); then built with `xcodebuild` for
  `generic/platform=iOS Simulator`, with no warning in what the kit wrote. No simulator is booted.

## Conformance on Seer

The call in `Schema/examples/seer.json` is the one the one-shot Seer prompt carries. Written into a project that
holds SeerKit's `Exchange`, `Highlight`, `Owner`, `SourceGroup` and `SourceDocument`, it writes 27 files into
`Components/Converse`, 22 of the kit and 5 conformances, and leaves the app only its page. The page body

```swift
ConverseStage(exchanges: chat.state.exchanges, send: { try await chat.send(text: $0) }, load: { try await chat.load() }, leading: { layout.present(.world) })
```

builds with it for the iPhone simulator and the Mac in Swift 6 (`ConverseBuildTests`). Every destination
(`seer`, `void.reply`, `echoes`, `contributions`, `contribution`, `threads`) opens the Seer tab, and the stage opens
the rest from the launch state.

Against Seer's scorecard (areas `void`, `echoes`, `contributions` and `threads`), the output matches every `code`
item: B-void-6 to 16, B-echoes-5 to 8, B-contributions-6 to 11 and B-threads-5 to 9. Every string the spec quotes for
the Void, Echoes, Contributions, Contribution Detail and Sinatra Threads is in the code. The `opens`, `text` and
`read` items are judged on the run's screenshots.

2026-11-15, against Seer's reference (`seer` in Sis): suite 40 tests (one gated), gated build green.
