# ConverseAgent

Give an app that talks with a model its conversation screens without drawing them by hand. Say which of your types
are the exchanges, the phrases a reply borrowed, the people whose documents shaped it and those documents, and
`converse` writes the stage that shows them: one exchange at a time, the reply typed out with a cursor and then
brushed where its sources' phrases are, a slow orb behind, and a Liquid Glass input at the bottom. Around it come the
transcript, the sheet of whose documents shaped a reply and what each earned, and a woven reading. What it writes is
plain SwiftUI that works in any app, with no Granite dependency in it.

## What you can ask

```
$converse the conversation screens over SeerKit's Exchange, Highlight, Owner, SourceGroup and SourceDocument
$converse a tutor's chat: turns as exchanges, quotes as highlights, sources and their pages, its views prefixed Tutor
$converse the stage with the app's brand fonts and accent, "speak into the void..." in the input
$converse open the transcript on launch for echoes, and a source's documents for contribution
```

Craft writes the call from your request, shows it on its agent map as `converse-1`, and builds and tests what it
writes with the turn.

## What you get

- **A stage, not a chat log.** The last exchange rises away as the next arrives, thinking dots wait for the reply,
  the reply types itself out, and its borrowed phrases are brushed in each owner's colour. A tap on a stroke opens
  that owner's documents.
- **The sheets it opens itself.** The transcript of every exchange, with copy on a long press; whose documents shaped
  a reply, with royalties, groups, tags and a group's documents pushed; and the weave, an animated canvas over words
  that open readings.
- **Your own types, shown as they are.** One line a type says which field is the prompt, the reply or the royalty;
  the views read protocols, and your types are made to conform to them without a change to the types themselves.
- **Your words, symbols, look and timing.** Every string, SF Symbol, font, colour and number has a key and a natural
  default. Change the placeholder, the reveal speed or the owners' palette with one line.
- **Every screen from a launch.** Name a launch destination and the state it opens in, a reply, the transcript, the
  sources, a group's documents or the weave, so tests and screenshots need no taps.
- **Views ready to drop in.** They take values and closures, hold no global state and route only to their own
  sheets, so your app keeps its navigation; a control with no action is not drawn. Every view has a `#Preview`, and
  every icon-only control is labelled for VoiceOver.

## How it works

- It reads each line and refuses one it cannot read with the reason and what the line takes, every bad line at once,
  and writes nothing.
- When your types are in the project, each mapping is checked against them, so a misspelt field is refused with the
  fields the type has.
- It writes from templates and asks no model, so the same call makes the same files every time.
- Every file is parsed with `swiftc -parse` before any lands, and they land together.
- What it makes is built and tested with the turn.

## Works well with

`converse` writes the conversation; the other Rao Craft Agents fill in the rest. `models` and `network` write the
types it maps and the client that sends a prompt, `mocks` the exchanges it shows before the model answers, and
`granite` the page that shows `ConverseStage` and the service that holds the conversation.

## Get it

In Craft, install Converse from the Agent Store, or run
`craft agents add https://github.com/rao-craft/ConverseAgent.git`, then say `$converse` in a request.

## Requirements

- A Mac on macOS 14 or later, with Xcode.
- The views target iOS 17 and macOS 14, use Liquid Glass on iOS 26 and macOS 26, and compile in Swift 5 and Swift 6
  language modes. They are plain SwiftUI: no Granite, and no package to add.
- MIT licensed.

## For developers

What a call takes and answers, every line, key and launch state, and the page body are in
[Schema/Converse.md](Schema/Converse.md). How it is measured is [TESTING.md](TESTING.md).
