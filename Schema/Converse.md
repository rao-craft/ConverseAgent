# craft-agent/1 · converse

Writes a conversation's screens as plain SwiftUI (a stage that types each reply out and brushes the phrases its sources gave, a glass input, the transcript, whose documents shaped a reply with their royalties, and a woven reading), made to show the app's own types from one mapping line a type.

converse's copy of Craft's agent standard (`craft-agent/1`, Craft's `Schema/Agent.md`), with the reference for every
field, line, key and launch state below it. **Changes** is converse's own log.

| File | What it holds |
| --- | --- |
| [`converse.input.schema.json`](converse.input.schema.json) | What it takes, as JSON Schema |
| [`converse.answer.schema.json`](converse.answer.schema.json) | What it answers: `granite-answer/1` with its own kinds |
| [`examples/seer.json`](examples/seer.json) | The call that writes Seer's stage, Echoes, Contributions and Threads |
| [`examples/seer.answer.json`](examples/seer.answer.json) | What that call answers, its paths relative to the project |
| [`examples/tutor.json`](examples/tutor.json) | A call for another app: a tutor with its own turn, quote, source and page types, its kit named `Tutor` |

## What it takes

| Field | Required | What it is |
| --- | --- | --- |
| `into` | no | the folder for the views, relative to the project; Components/Converse when left out |
| `prefix` | no | the word the kit's types start with in place of Converse, when the app already has those names: Void writes VoidStage |
| `imports` | no | modules the conformances import, such as the package a mapped type is declared in |
| `mappings` | no | one line a role (exchange, highlight, owner, group, document, reading): `exchange: Exchange prompt=prompt reply=reply highlights=highlights owners=owners`; a bare path is read off the value, anything else is Swift that may name `value` |
| `look` | no | fonts and colours by role, several to a line: `title = Font.brandTitle, body = Font.brandBody, accent = Color.accent, card = #FFFFFF / #FFFFFF 0.10`; roles: title, body, body2, note, note2, accent, background, card, cardShadow, buttonShadow |
| `strings` | no | words by key, several to a line: `stage.title = "Seer", sources.royalty = "Royalty: {n}%"`; a word in quotes keeps its spaces |
| `symbols` | no | SF Symbols by key: `leading = infinity, weave = bonjour` |
| `tuning` | no | numbers by group or key: `reveal: base 15, jitter 10, wait 1.2`, `stroke.opacity = 0.20`, `palette = (0.38, 0.55, 0.38) (0.56, 0.49, 0.32)` |
| `launch` | no | one line a destination and the state the stage opens in: empty, reply(i), transcript(i, …), sources(i), source(i, "group") or weave(i, …), a reading's word in quotes opening it (`weave(0, "outward")`), and `large` after a state that opens a sheet for its full height: `contribution = source(0, "Orbital Mechanics")`, `echoes.full = transcript(0) large` |
| `readings` | no | one line a word of the weave and the reading it opens: `outward: The weft is running ahead of the warp.` |

`directory` is filled by Craft with the project folder. The person's request and the host's model are offered
beside the call, never in it. Every field may be left out: the least call writes the kit with its own values, its
samples and the system's look.

## What it makes

| Kind | What | Into | Never |
| --- | --- | --- | --- |
| `view` | a conversation's screens as reusable SwiftUI views: ConverseStage (one exchange at a time, the reply typed out and brushed, a glass input), and the sheets it opens itself (ConverseTranscript, ConverseSources with ConverseSourceDetail, ConverseWeave); a page shows ConverseStage(exchanges:send:) | `Components/Converse/*` | routes past its own sheets; never a page, a service, a client or a model type |
| `conformance` | the app's own types made the views' values: one extension a mapping line | `Components/Converse/Conformances/*` | a change to the app's types themselves |

Every file is a template filled from the call: the same call writes the same bytes. The views are plain SwiftUI for
iOS 17 and macOS 14, with Liquid Glass behind `if #available(iOS 26.0, macOS 26.0, *)`, no Granite import and no
global mutable state. Each view has a `#Preview` over the kit's samples, and each icon-only control an accessibility
label. Every type the kit declares starts with `Converse` (or the call's `prefix`), so one word renames them all.

## What it answers

A `granite-answer/1` answer (Granite's `Schema/GraniteAgent.md` §4.2): `paths`, `made` against `expected` by kind and
name, `problems` for what it could only do in part, and its own keys beside them:

- `path`: the first file written;
- `views`: the views written, the five roots first (`ConverseStage`, `ConverseTranscript`, `ConverseSources`,
  `ConverseSourceDetail`, `ConverseWeave`);
- `conformances`: one line a mapping (`Exchange: exchange`);
- `initializers`: each root's initializer as one line, with the app's exchange type in it, so the host can write the
  page body;
- `launch`: the launch states, one line a destination (`void.reply = reply(0)`);
- `notes`: one sentence each for what the call left out or the app still has to do.

`expected` holds the five roots and one conformance a mapping line; `made` holds each file of views by the view it
opens with, and each conformance, every one `written`, `rewritten` or `unchanged`. The same call made again answers
every file `unchanged`.

## How it refuses

With an `AgentRefusal` of kind `call`, every reason at once, each naming the field, the line and what it takes:

> mappings: \`exchange Exchange prompt=prompt\`: a mapping is \`role: Type word=value …\`, like \`exchange: Exchange prompt=prompt reply=reply\`, and this has no colon
>
> tuning: \`reveal: speed 3\`: \`speed\` is not a key of reveal: it takes base, jitter, wait, cursor, cursorOpacity

When the app's own types are in the project, every path is checked against them: a field a type lacks is refused
with the fields it has, `owner_id` is written `ownerId` with a note, a field of a type the word cannot show is
refused with what it takes, and a type with no `id` must say which field tells one from another. A type declared in
a local package is imported. Nothing is written until every problem is fixed and every file parses
(`swiftc -parse`).

## The roots and the page body

One root sits in the app's navigation stack, whose bar it fills: the stage. It opens the transcript, a reply's
sources (pushing a group's documents) and the weave itself, as sheets, and leaves every other route to the app. The
other four roots are there for an app that shows one on its own. As the answer gives them, for a call that maps
`Exchange`:

```swift
ConverseStage(exchanges: [Exchange], readings: [any ConverseReadingRepresentable] = ConverseReadings.all, send: @MainActor (String) async throws -> Void, load: (@MainActor () async throws -> Void)? = nil, leading: (@MainActor () -> Void)? = nil, leadingActive: Bool = false, listen: (@MainActor () -> Void)? = nil, listening: Bool = false, documents: (([String]) -> some View)? = nil)
ConverseTranscript(exchanges: [ConverseExchange], readings: [ConverseReading], opensWeave: Bool = false, weaveLarge: Bool = false, weaveReading: String? = nil)
ConverseSources(exchange: ConverseExchange?, opening: String? = nil)
ConverseSourceDetail(documents: [ConverseDocument], close: () -> Void)
ConverseWeave(readings: [ConverseReading], entered: Bool = false, open: String? = nil)
```

- `exchanges`: the conversation, oldest first; the stage shows the last one, and the next one sent arrives as it
  rises away.
- `send`: makes the app add an exchange. Its reply may come later: the stage shows thinking dots until the list
  holds the exchange with a reply, then types it out. Send stays off while a reply is awaited.
- `load`: fetches the conversation when a launch names an exchange the list does not hold yet.
- `leading`: draws the bar's leading button (symbol `leading`), green while `leadingActive`; no button without it.
- `listen`: draws a microphone in the input, filled while `listening`; no microphone without it.
- `readings`: the weave's rows; the `readings` lines by default. With none, the transcript draws no weave button.
- `documents`: the app's own view of documents by id, shown from a brushed phrase or a document row; the kit lists
  them itself without it.

Every closure runs on the main actor. Seer's page, its chat relay holding the conversation and its layout relay the
app's sheets, writes:

```swift
ConverseStage(exchanges: chat.state.exchanges, send: { try await chat.send(text: $0) }, load: { try await chat.load() }, leading: { layout.present(.world) })
```

The stage fills the stack's bar inline: its title (`stage.title`) in the centre, its buttons at the ends. The page
keeps that bar shown and sets no title display mode of its own; a `.navigationTitle` it writes (GraniteAgent's blank
page writes one) shows only as the stage's own title, which takes its place.

The launch states are the stage's: every destination opens the page that shows the stage (Seer's tab), and the
stage opens the rest.

## Mapping lines

```
exchange: Exchange prompt=prompt reply=reply highlights=highlights owners=owners
highlight: Highlight phrase=phrase owner=ownerId
owner: Contributor id=ownerId name=name royalty=royalty mine=isAccount tone=tone documents=documents groups=groups
group: SourceGroup id=name name=name summary=summary tags=tags documents=documents
document: SourceDocument id=documentId text=text influence=influence
reading: Mood word=title text=line
```

A role, a colon, the type (`SeerKit.Exchange` names its module), then one `word=right side` a thing the views show,
with spaces or commas between them. A right side that is a bare path (`ownerId`, `meta?.title`) is read off the
value; anything else is Swift that may name `value` (`royalty=value.share * 100`). A word the line leaves out shows
its empty value. A list (`highlights`, `owners`, `documents`, `groups`) needs its element's own line, and a role with
an `id` reads the type's own `id` unless the line says `id=`. One line a type and role.

Each line writes one extension into `Conformances/`, `Exchange+ConverseExchange.swift`: the type conforms to
`ConverseExchangeRepresentable`, whose one requirement is the kit's own value, `var converseExchange: ConverseExchange`.
The views never see the app's types. With no exchange line a page passes `[ConverseExchange]`.

| Role | Word | Takes | When left out | What it is |
| --- | --- | --- | --- | --- |
| `exchange` | `id` | String, Substring, UUID, URL or a whole number | the type's own `id` | what tells one exchange from another; say `id=` only when the type has no `id` |
|  | `prompt` | String, Substring, UUID, URL or a whole number | `""` | the prompt, as the person wrote it |
|  | `reply` | String or String? | `nil` | the reply; nothing while it is thought of |
|  | `highlights` | a list of values a `highlight:` line maps | `[]` | the reply's phrases and whose each is |
|  | `owners` | a list of values an `owner:` line maps | `[]` | whose documents shaped the reply, with their royalty |
| `highlight` | `phrase` | String, Substring, UUID, URL or a whole number | `""` | the words of the reply to brush |
|  | `owner` | String, Substring, UUID, URL or a whole number | `""` | whose they are: the owner's id or name |
| `owner` | `id` | String, Substring, UUID, URL or a whole number | the type's own `id` | what tells one owner from another; say `id=` only when the type has no `id` |
|  | `name` | String, Substring, UUID, URL or a whole number | `""` | the owner's name |
|  | `royalty` | a whole percent or a share of 1 (Int, Double, Float, CGFloat, Decimal) | `0` | the share of the reply they earned, a whole percent (or a fraction of 1) |
|  | `mine` | Bool | `false` | whether it is the person's own library |
|  | `tone` | Int (or another integer type) | `nil` | which palette colour is theirs; their place among the reply's owners when left out |
|  | `documents` | a list of values a `document:` line maps | `[]` | their documents behind the reply (the Library's rows when it is mine) |
|  | `groups` | a list of values a `group:` line maps | `[]` | their documents in groups (an owner's rows) |
| `group` | `id` | String, Substring, UUID, URL or a whole number | the type's own `id` | what tells one group from another; say `id=` only when the type has no `id` |
|  | `name` | String, Substring, UUID, URL or a whole number | `""` | the group's name |
|  | `summary` | String, Substring, UUID, URL or a whole number | `""` | one line on what it holds |
|  | `tags` | [String], or one String split at commas | `[]` | its tags, shown as chips |
|  | `documents` | a list of values a `document:` line maps | `[]` | its documents behind the reply |
| `document` | `id` | String, Substring, UUID, URL or a whole number | the type's own `id` | what tells one document from another; say `id=` only when the type has no `id` |
|  | `text` | String, Substring, UUID, URL or a whole number | `""` | its text; a row shows its start |
|  | `influence` | a whole percent or a share of 1 (Int, Double, Float, CGFloat, Decimal) | `0` | how much it shaped the reply, a whole percent (or a fraction of 1) |
| `reading` | `word` | String, Substring, UUID, URL or a whole number | `""` | the word the weave shows |
|  | `text` | String, Substring, UUID, URL or a whole number | `""` | the reading it opens |

## Look

`look` lines map a role to the app's own Swift (`title = Font.brandTitle`, `accent = Color.accent`) or give a colour,
several to a line between commas. A colour is `#AE9060`, `rgb(174, 144, 96)` or `(0.68, 0.56, 0.38)`, with an opacity
after it (`#8E8E8E 0.14`), `clear`, or a light and a dark one between ` / ` (`#FFFFFF / #FFFFFF 0.10`). They land in
`ConverseLook`, the one enum the views read. A role left out keeps the system's value below, so the views build in
any app.

| Role | Kind | When unmapped | What it is |
| --- | --- | --- | --- |
| `title` | Font | `.system(size: 24, design: .serif)` | bar titles |
| `body` | Font | `.system(size: 20, design: .serif)` | the stage's prompt, a row's word in the weave |
| `body2` | Font | `.system(size: 18, design: .serif)` | the transcript's prompts, a group's name |
| `note` | Font | `.system(size: 18, weight: .light, design: .serif)` | the stage's reply, the empty sources line |
| `note2` | Font | `.system(size: 16, weight: .light, design: .serif)` | the transcript's replies, a group's summary |
| `accent` | Color | `Color.accentColor` | bar buttons, chips |
| `background` | Color | `ConverseLook.system` | behind the stage |
| `card` | Color | `ConverseLook.dynamic(light: Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255), dark: Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255).opacity(0.10))` | an indicator's face |
| `cardShadow` | Color | `ConverseLook.dynamic(light: Color(red: 142 / 255, green: 142 / 255, blue: 142 / 255).opacity(0.14), dark: .clear)` | the pill's shadow |
| `buttonShadow` | Color | `ConverseLook.dynamic(light: Color(red: 142 / 255, green: 142 / 255, blue: 142 / 255).opacity(0.40), dark: .clear)` | an indicator's shadow |

## Strings

`strings` lines set the words the views show, several to a line: `stage.title = "Seer", echoes.title = "Echoes"`. A
word in quotes keeps its spaces (`" speak into the void..."`); a bare word is trimmed. A key that shows a number says
where with `{n}` (`sources.royalty = "Royalty: {n}%"`), and a key that shows none is refused one. An empty
`stage.title` leaves the bar without a title.

| Key | Default | What it is |
| --- | --- | --- |
| `stage.title` | `"Conversation"` | the stage's title in the bar; empty for none |
| `stage.placeholder` | `"Ask anything..."` | the input's placeholder |
| `stage.cursor` | `" \|"` | the cursor after the text a reply has shown so far |
| `stage.echoesLabel` | `"Show the conversation"` | the label of the bar button that opens and closes the transcript |
| `stage.leadingLabel` | `"More"` | the label of the bar's leading button |
| `stage.keyboardLabel` | `"Hide keyboard"` | the label of the button that drops the keyboard |
| `stage.sendLabel` | `"Send"` | the send button's label |
| `stage.listenLabel` | `"Speak"` | the microphone's label, when the page gives `listen` |
| `echoes.title` | `"Transcript"` | the transcript's title |
| `echoes.copy` | `"Copy to clipboard"` | the long press's action on a prompt or a reply |
| `echoes.weaveLabel` | `"Show the weave"` | the label of the transcript's leading button, which opens the weave |
| `close` | `"Close"` | the label of a sheet's close button |
| `sources.title` | `"Sources"` | the sources sheet's title |
| `sources.library` | `"Library"` | the header of the person's own documents |
| `sources.royalty` | `"Royalty: {n}%"` | an owner's share of the reply |
| `sources.influence` | `"Influence: {n}%"` | a document's share |
| `sources.docs` | `"{n} docs"` | a group's count of documents |
| `sources.doc` | `"1 doc"` | a group of one document |
| `sources.more` | `"..."` | what follows a document's cut text |
| `sources.emptyTitle` | `"No Sources"` | the title when no one's documents shaped the reply |
| `sources.emptyText` | `"Nothing in anyone's library shaped this reply."` | the line under it |
| `detail.title` | `"Documents"` | a group's documents' title |
| `weave.title` | `"The Weave"` | the weave's title |
| `weave.separator` | `"  ·  "` | what stands between the weave's words |

## Symbols

`symbols` lines name the SF Symbols the views draw, several to a line: `leading = infinity, weave = bonjour`.

| Key | Default | What it is |
| --- | --- | --- |
| `leading` | `sparkles` | the bar's leading button, when the page gives `leading` |
| `echoes` | `line.3.horizontal` | the bar button that opens the transcript |
| `close` | `xmark` | a sheet's close button, and the bar button while the transcript is open |
| `keyboard` | `chevron.down` | the bar button that drops the keyboard |
| `send` | `arrow.up` | the send button |
| `listen` | `mic` | the microphone, when the page gives `listen` |
| `listening` | `mic.fill` | the microphone while it listens |
| `weave` | `bonjour` | the transcript's leading button, which opens the weave |
| `copy` | `document.on.clipboard` | the long press's copy action |
| `document` | `text.document.fill` | a document's indicator |
| `person` | `person.fill` | an owner's indicator |
| `empty` | `magnifyingglass` | the empty sources sheet |

## Tuning

`tuning` lines set every number the views are drawn and moved by:

```
reveal: base 15, jitter 10, wait 1.2, cursor 0.55
arrive: curve 0.16 1 0.3 1, duration 0.9, drop 16, blur 6
stroke.opacity = 0.20
palette = (0.38, 0.55, 0.38) (0.56, 0.49, 0.32) #F0909F
```

A group, a colon, then `key value` pairs between commas; or a whole key, `=` or `:`, and its value. A number lands
as the call wrote it (`0.20` is `.opacity(0.20)`). A **number** is zero or more; a **signed** number may be below
zero; a **count** is a whole number; **2 numbers** or **4 numbers** are written one after another; a **colour** is
`rgb(70, 50, 110)` (0 to 255), `(0.38, 0.55, 0.38)` (0 to 1) or `#AE9060`, and **colours** are several in a row. A
key left out keeps its default, which is the original's. `stroke.top` and `stroke.bottom` take the lower number
first, and `pill.lines` is at least 1.

**The reveal: a reply typed out character by character.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `reveal.base` | `15` | number | milliseconds each character waits before the next |
| `reveal.jitter` | `10` | number | random milliseconds added to each wait, from 0 to this |
| `reveal.wait` | `1.2` | number | seconds from the send before the reply starts to show |
| `reveal.cursor` | `0.55` | number | seconds between the cursor's blinks |
| `reveal.cursorOpacity` | `0.4` | number | the cursor's opacity |

**The exchange that leaves as the next arrives.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `leave.duration` | `1.0` | number | seconds the leaving exchange eases out over |
| `leave.rise` | `30` | number | points it rises as it leaves |
| `leave.scale` | `0.96` | number | the scale it shrinks to |
| `leave.blur` | `10` | number | the blur it dissolves into |
| `leave.remove` | `1.1` | number | seconds from the send until it is removed |

**The exchange that arrives.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `arrive.curve` | `0.16 1 0.3 1` | 4 signed numbers | the timing curve's control points it comes to rest by |
| `arrive.duration` | `0.9` | number | seconds it takes to come to rest |
| `arrive.drop` | `16` | number | points below its place it starts from |
| `arrive.blur` | `6` | number | the blur it starts from |

**The strokes over a reply's phrases.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `stroke.opacity` | `0.20` | number | the opacity a stroke is filled at |
| `stroke.fade` | `0.7` | number | seconds a stroke fades in over |
| `stroke.stagger` | `0.15` | number | seconds between the strokes of a paragraph |
| `stroke.width` | `12` | number | points a stroke is wider than its words |
| `stroke.height` | `8` | number | points a stroke is taller than its words |
| `stroke.rows` | `7` | number | points between the reply's lines once it is brushed |
| `stroke.tilt` | `0.8` | number | how far a stroke's edges tilt from end to end, at most |
| `stroke.pinch` | `0.22 0.143` | 2 numbers | how much the left and the right tips are pinched, of the height |
| `stroke.top` | `-0.25 0.10` | 2 signed numbers | how far the top edge's points move, of the height (up is below zero) |
| `stroke.bottom` | `-0.10 0.25` | 2 signed numbers | how far the bottom edge's points move, of the height |
| `palette` | `(0.38, 0.55, 0.38) (0.56, 0.49, 0.32) (0.94, 0.56, 0.68) (0.22, 0.44, 0.65) (0.65, 0.40, 0.55)` | colours | the owners' colours, in order |

**The orb behind the stage.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `orb.size` | `500` | number | the orb's width |
| `orb.radius` | `250` | number | the radius its gradient fades out at |
| `orb.inner` | `rgb(70, 50, 110)` | colour | the colour at its centre |
| `orb.opacity` | `0.045` | number | the opacity at its centre |
| `orb.outer` | `rgb(40, 60, 90)` | colour | the colour halfway out |
| `orb.outerOpacity` | `0.02` | number | the opacity halfway out |
| `orb.drift` | `30` | number | seconds it drifts one way |
| `orb.offset` | `5` | number | points it drifts each way |
| `orb.scales` | `0.98 1.02` | 2 numbers | the scales it drifts between |
| `orb.center` | `0.45` | number | where its centre rests, of the screen's height |

**The dot of an empty stage.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `idle.size` | `4` | number | the dot's width at rest |
| `idle.grow` | `8` | number | its width at the top of a breath |
| `idle.opacity` | `0.12` | number | its opacity at rest |
| `idle.glow` | `0.42` | number | its opacity at the top of a breath |
| `idle.breath` | `4` | number | seconds a breath takes |
| `idle.fade` | `0.4` | number | seconds it fades out and back over |

**The dots while a reply is thought of.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `dots.size` | `2.5` | number | each dot's width |
| `dots.spacing` | `7` | number | points between the dots |
| `dots.height` | `24` | number | the row's height |
| `dots.inset` | `4` | number | the row's inset |
| `dots.low` | `0.2` | number | a dot's opacity at its faintest |
| `dots.high` | `0.55` | number | a dot's opacity at its brightest |
| `dots.duration` | `2` | number | seconds from faintest to brightest |
| `dots.delay` | `0.35` | number | seconds each dot waits after the one before |

**The stage and its exchange column.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `stage.top` | `8` | number | the stage's padding at the top |
| `stage.side` | `24` | number | the stage's padding at the sides |
| `stage.bottom` | `24` | number | the stage's padding above the pill |
| `column.width` | `460` | number | the exchange column's widest |
| `column.gap` | `18` | number | points between the prompt and the reply |
| `column.paragraphs` | `16` | number | points between a reply's paragraphs |
| `column.promptSpacing` | `5` | number | the prompt's line spacing |
| `column.promptKerning` | `0.2` | number | the prompt's kerning |
| `column.replySpacing` | `7` | number | the reply's line spacing |
| `column.replyKerning` | `0.3` | number | the reply's kerning |
| `column.code` | `15` | number | the size of code in a reply |

**The ink each type role is set in: the primary colour at these opacities.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `ink.title` | `0.75` | number | titles' opacity |
| `ink.body` | `0.75` | number | the stage's prompt and a weave row's word |
| `ink.body2` | `0.75` | number | the transcript's prompts and a group's name |
| `ink.note` | `0.6` | number | the stage's reply and the empty sources line |
| `ink.note2` | `0.6` | number | the transcript's replies and a group's summary |

**The input pill.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `pill.radius` | `24` | number | the pill's corner radius |
| `pill.inset` | `16` | number | points from the screen's sides and bottom |
| `pill.vertical` | `14` | number | its padding above and below |
| `pill.horizontal` | `16` | number | its padding at the sides |
| `pill.gap` | `12` | number | points between the field and the send button |
| `pill.fieldBottom` | `2` | number | the field's padding below its last line |
| `pill.micGap` | `14` | number | points between the send arrow and the microphone, when the page gives `listen` |
| `pill.mic` | `16` | number | the microphone's square |
| `pill.listenScale` | `1.1` | number | the microphone's scale while it listens |
| `pill.micEase` | `0.2` | number | seconds the microphone eases between its states |
| `pill.font` | `19` | number | the field's font size |
| `pill.lines` | `5` | count | the lines the field grows to before it scrolls |
| `pill.text` | `0.8` | number | the field's text opacity |
| `pill.hint` | `0.3` | number | the placeholder's opacity |
| `pill.caret` | `0.3` | number | the caret's opacity |
| `pill.send` | `14` | number | the send arrow's size |
| `pill.ready` | `0.75` | number | the arrow's opacity when it can send |
| `pill.idle` | `0.3` | number | its opacity when it cannot |
| `pill.ease` | `0.25` | number | seconds the arrow eases between them |
| `pill.shadow` | `2 4` | 2 numbers | the pill's shadow radius and drop |

**The glass bands at the screen's edges.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `edge.height` | `150` | number | each band's height |
| `edge.tint` | `0.07` | number | the white tint at the screen's edge |
| `edge.fade` | `0.2` | number | seconds the top band fades in and out over |

**The transcript.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `echoes.top` | `12` | number | the list's padding at the top |
| `echoes.side` | `24` | number | its padding at the sides |
| `echoes.bottom` | `40` | number | its padding at the bottom |
| `echoes.block` | `24` | number | points below each exchange |
| `echoes.rule` | `16 1` | 2 numbers | the rule's width and height |
| `echoes.ruleOpacity` | `0.5` | number | the rule's opacity |
| `echoes.ruleGap` | `32` | number | points below the rule |
| `echoes.promptSpacing` | `4` | number | a prompt's line spacing |
| `echoes.replyGap` | `16` | number | points between a prompt and its reply |
| `echoes.replySpacing` | `6` | number | a reply's line spacing |
| `echoes.paragraphs` | `16` | number | points between a reply's paragraphs |
| `echoes.dot` | `2` | number | each still dot's width while a reply is thought of |
| `echoes.dotSpacing` | `4` | number | points between the still dots |
| `echoes.dotOpacity` | `0.4` | number | the still dots' opacity |
| `echoes.weavePadding` | `-2` | signed | the weave button's padding at its sides |

**The sources sheet and its detail.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `sources.cut` | `27` | count | the characters a document's row shows before "..." |
| `sources.indicator` | `36` | number | the round indicator's width |
| `sources.wash` | `0.25` | number | the background's wash over an indicator's face |
| `sources.symbol` | `0.8` | number | an indicator symbol's opacity |
| `sources.ring` | `1` | number | an indicator's ring |
| `sources.shadow` | `2 2` | 2 numbers | an indicator's shadow radius and drop |
| `sources.fade` | `0.8` | number | where an indicator face's gradient ends, of its colour |
| `sources.gap` | `12` | number | points between an indicator and its words |
| `sources.ownerGap` | `16` | number | points between an indicator and an owner's name in a row of its own |
| `sources.rowPadding` | `4` | number | a group row's padding above and below |
| `sources.stack` | `4` | number | points between a group row's lines |
| `sources.ownerFont` | `14` | number | an owner's name size |
| `sources.royaltyFont` | `12` | number | an owner's royalty size |
| `sources.countFont` | `12` | number | a group's document count size |
| `sources.countInk` | `0.35` | number | the count's opacity |
| `sources.chip` | `11` | number | a tag chip's font size |
| `sources.chipPadding` | `8 2` | 2 numbers | a chip's padding across and down |
| `sources.chipInk` | `0.8` | number | a chip's text opacity |
| `sources.chipFill` | `0.10` | number | a chip's fill opacity |
| `sources.chipBorder` | `0.2` | number | a chip's border opacity |
| `sources.emptyIcon` | `50` | number | the empty state's symbol size |
| `sources.emptyPadding` | `42` | number | the empty state's side padding |
| `sources.emptyTitleGap` | `3` | number | points below the empty state's title |
| `sources.emptyBottom` | `15` | number | points below the empty state's line |
| `detail.margin` | `4` | number | the detail list's vertical content margin |
| `detail.gap` | `16` | number | points between an indicator and a document's id |

**The weave.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `weave.height` | `336` | number | the canvas's height |
| `weave.speed` | `0.4` | number | the canvas's time, per second |
| `weave.frames` | `60` | number | the canvas's frames a second, at most |
| `weave.bleed` | `8` | number | points the canvas runs past each side |
| `weave.canvasTop` | `4` | number | the canvas's padding above |
| `weave.canvasBottom` | `12` | number | the canvas's padding below |
| `weave.warp` | `16` | count | the warp's lines across |
| `weave.warpTop` | `75` | number | points above the centre the warp starts |
| `weave.warpSpacing` | `10` | number | points between warp lines |
| `weave.warpAmplitude` | `3` | number | how far a warp line waves |
| `weave.warpFrequency` | `0.006` | number | a warp line's wave, per point across |
| `weave.warpDrift` | `0.1` | number | a warp line's wave, per unit of time |
| `weave.warpPhase` | `0.45` | number | each warp line's phase after the one before |
| `weave.warpColor` | `rgb(160, 140, 110)` | colour | the warp's colour |
| `weave.warpOpacity` | `0.06` | number | the warp's opacity |
| `weave.warpWidth` | `0.6` | number | a warp line's width |
| `weave.warpStep` | `2` | number | points between a warp line's samples |
| `weave.warpSwell` | `2` | number | how far a warp line's second, slower wave moves it |
| `weave.warpSwellFrequency` | `0.0025` | number | that wave, per point across |
| `weave.warpSwellDrift` | `0.05` | number | that wave, per unit of time |
| `weave.warpFlicker` | `0.015` | number | how far a warp line's opacity wavers |
| `weave.warpFlickerRate` | `0.07` | number | its wavering, per unit of time |
| `weave.warpFlickerPhase` | `0.6` | number | each warp line's wavering after the one before |
| `weave.weft` | `7` | count | the weft's lines down |
| `weave.weftSpacing` | `11` | number | points between weft lines |
| `weave.weftAmplitude` | `37` | number | how far a weft line waves |
| `weave.weftBase` | `0.5` | number | the first weft line's share of that |
| `weave.weftGrowth` | `0.06` | number | the share each weft line adds |
| `weave.weftFrequency` | `0.0118` | number | a weft line's wave, per point down |
| `weave.weftDrift` | `0.54` | number | a weft line's wave, per unit of time |
| `weave.weftPhase` | `1.1` | number | each weft line's phase after the one before |
| `weave.weftColor` | `rgb(130, 105, 60)` | colour | the weft's colour |
| `weave.weftCenter` | `0.5 1.5` | 2 numbers | the middle weft line's opacity and width |
| `weave.weftOpacity` | `0.05 0.36` | 2 numbers | the other weft lines' opacity: at the edge, and added toward the middle |
| `weave.weftWidth` | `0.7` | number | the other weft lines' width |
| `weave.weftStep` | `1.5` | number | points between a weft line's samples |
| `weave.weftEcho` | `0.1` | number | a weft line's second wave, of its swing |
| `weave.weftEchoFrequency` | `2.2` | number | that wave's frequency, of the first's |
| `weave.weftEchoDrift` | `0.55` | number | that wave's phase, of the first's |
| `weave.weftSway` | `5` | number | how far the whole weft sways |
| `weave.weftSwayFrequency` | `0.004` | number | its sway, per point down |
| `weave.weftSwayDrift` | `0.07` | number | its sway, per unit of time |
| `weave.glows` | `8` | count | the glows |
| `weave.glowReach` | `32` | number | how far a glow sways |
| `weave.glowFrequency` | `0.22` | number | a glow's sway, per unit of time |
| `weave.glowCurve` | `0.012` | number | a glow's sway, per point down |
| `weave.glowBreath` | `0.45` | number | a glow's breathing, per unit of time |
| `weave.glowPhase` | `1.9` | number | each glow's phase after the one before |
| `weave.glowTop` | `55` | number | points above the centre the glows start |
| `weave.glowSpacing` | `15` | number | points between glows |
| `weave.glowColor` | `rgb(150, 125, 75)` | colour | a glow's colour |
| `weave.glowSize` | `7 13` | 2 numbers | a glow's radius, smallest and largest |
| `weave.glowOpacity` | `0.03 0.06` | 2 numbers | a glow's opacity, faintest and brightest |
| `weave.words` | `18` | number | the words' font size |
| `weave.tracking` | `0.8` | number | the words' tracking |
| `weave.wordsInk` | `0.6` | number | the words' opacity |
| `weave.wordsTop` | `16` | number | points above the words |
| `weave.wordsBottom` | `8` | number | points below them |
| `weave.wordRise` | `5` | number | points a word rises as it fades in |
| `weave.separatorSize` | `13` | number | the separator's font size |
| `weave.separatorInk` | `0.42` | number | the separator's opacity |
| `weave.separatorPadding` | `4` | number | points at each side of a separator |
| `weave.separatorFade` | `2.0` | number | seconds a separator fades in over |
| `weave.rule` | `40 0.5` | 2 numbers | the short rule under the words: width and height |
| `weave.ruleColor` | `rgb(140, 120, 85)` | colour | the rule's colour |
| `weave.ruleOpacity` | `0.18` | number | the rule's opacity |
| `weave.rulePadding` | `8` | number | points above and below the rule |
| `weave.ruleFade` | `2.5` | number | seconds the rule fades in over |
| `weave.inset` | `28` | number | the rows' inset from the sides |
| `weave.dot` | `5` | number | a row's dot |
| `weave.dotGap` | `14` | number | points between a row's dot and its word |
| `weave.rowPadding` | `24` | number | a row's padding above and below |
| `weave.rowRise` | `8` | number | points a row rises as it fades in |
| `weave.wordTracking` | `0.4` | number | a row's word's tracking |
| `weave.reading` | `16` | number | a reading's font size |
| `weave.readingInk` | `0.62` | number | a reading's opacity |
| `weave.readingSpacing` | `8` | number | a reading's line spacing |
| `weave.readingInset` | `19` | number | a reading's inset, under its word |
| `weave.readingBottom` | `20` | number | points below a reading |
| `weave.readingWidth` | `360` | number | a reading's widest |
| `weave.readingIn` | `0.6` | number | seconds a reading eases in over |
| `weave.readingOut` | `0.3` | number | seconds it eases out over |
| `weave.inkLight` | `rgb(90, 72, 45)` | colour | the words' ink in light mode |
| `weave.inkDark` | `rgb(214, 196, 164)` | colour | the words' ink in dark mode |
| `weave.readingLight` | `rgb(75, 62, 40)` | colour | a reading's ink in light mode |
| `weave.readingDark` | `rgb(214, 196, 164)` | colour | a reading's ink in dark mode |
| `weave.dotOpen` | `rgb(130, 105, 60)` | colour | the open row's dot |
| `weave.dotOpenOpacity` | `0.5` | number | its opacity |
| `weave.dotClosed` | `rgb(155, 138, 108)` | colour | a closed row's dot |
| `weave.dotClosedOpacity` | `0.22` | number | its opacity |
| `weave.dotBreath` | `1.75` | number | seconds an open dot's breath takes |
| `weave.dotBreaths` | `0.25 0.6` | 2 numbers | the opacities it breathes between |
| `weave.divider` | `rgb(150, 132, 105)` | colour | the hairline between rows |
| `weave.dividerOpacity` | `0.1` | number | its opacity |
| `weave.dividerHeight` | `0.5` | number | its height |
| `weave.endDot` | `4` | number | the breathing dot at the foot of the page |
| `weave.endTop` | `48` | number | points above it |
| `weave.endBottom` | `80` | number | points below it |
| `weave.endFade` | `4.5` | number | seconds it fades in over |
| `weave.entrance` | `0.4` | number | seconds after the sheet appears that its entrance begins |
| `weave.toggle` | `0.4` | number | seconds a reading opens and closes over |
| `weave.canvasFade` | `2.2` | number | seconds the canvas fades in over |
| `weave.wordFade` | `1.8` | number | seconds each word fades in over |
| `weave.wordStagger` | `0.4` | number | seconds between the words |
| `weave.rowFade` | `1.2` | number | seconds each row fades in over |
| `weave.rowStart` | `2.0` | number | seconds before the rows start |

**Launch: how a destination opens.**

| Key | Default | Takes | What it is |
| --- | --- | --- | --- |
| `launch.nested` | `0.6` | number | seconds before a sheet opened over another sheet at launch |

## Launch

```
seer = empty
void.reply = reply(0)
echoes = transcript(0)
contributions = sources(0)
contribution = source(0, "Orbital Mechanics")
threads = weave(0)
echoes.full = transcript(0) large
contributions.full = sources(0) large
threads.full = weave(0) large
```

`launch` maps a `-destination` name to the state the stage opens in, one line a destination. The kit writes
`ConverseLaunch`, which the stage reads once as it appears (the launch argument `-destination <name>`, through
`UserDefaults`); a name no line maps opens the stage as it is. An index is an exchange's place in the app's list,
from 0; the brackets may be left out (`source 0 "Orbital Mechanics"`), and a missing index is 0. A state that names
an exchange the list does not hold yet calls `load` first. A height after a state that opens a sheet, `medium` or
`large`, opens its sheets at that detent (`echoes.full = transcript(0) large`); medium when left out. `empty` and
`reply(i)` open no sheet and take none.

| State | Opens |
| --- | --- |
| `empty` | the empty stage, its dot breathing, whatever the list holds |
| `reply(i)` | the stage on exchange `i`, its reply shown whole and brushed |
| `transcript(i, …)` | the stage on the last of them, and the transcript sheet over it holding those exchanges |
| `sources(i)` | the stage on exchange `i`, and its sources sheet over it |
| `source(i, "group")` | the sources sheet of exchange `i` with that group's documents pushed (by name or id) |
| `weave(i, …)` | the transcript of those exchanges, then the weave over it (`launch.nested` seconds later), its entrance done and its readings closed; a reading's word in quotes after the indices opens that one (`weave(0, "outward")`); with `large`, the transcript and the weave both open at full height |

The app's navigation opens the page that shows the stage for each name; the stage opens its own sheets and pushes.

## Readings

```
curious: The questions keep reaching past the lesson.
steady: You come back every evening, a little further each time.
```

One line a word of the weave: the word, a colon, and the reading it opens. The words stand across the weave in
order, and each one is a row that opens its reading. They land in `ConverseReadings.all`, the stage's default
`readings`; a `reading:` mapping line makes the app's own type one instead.

## Changes

Each change made to make this agent more precise, dated, with the run that measured it and what it made of what it
was asked before and after (`TESTING.md`). Newest first.

### 2026-11-15 · a sheet's height, one exchange, owners with no id

A launch state takes a height after it (`echoes.full = transcript(0) large`), so a `.full` destination opens the
same sheet at the large detent; `weave` takes a reading's word in quotes and opens no reading without one, as the
original's Thread opens. The Seer call holds one exchange (`echoes = transcript(0)`, `threads = weave(0)`), as the
reference screens do, and maps SeerKit's per-reply owners, `Contributor`, `SourceGroup` and `SourceDocument`, which
have no `id` (`id=ownerId`, `id=name`, `id=documentId`). The first note says the page keeps the stage's bar.

Measured: not yet.

### 2026-11-15 · first cut

converse writes the conversation's screens for the Seer measure: the stage with its reveal, departure, arrival,
thinking dots, brushed phrases, orb and glass input; the transcript; the sources sheet with a group's documents
pushed; and the weave. The Seer call builds for the iPhone simulator with its stand-in app (`TESTING.md`).

Measured: not yet. The Seer measure's next run is the first.
