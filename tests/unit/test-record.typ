// The slide record: one validated dictionary every slide passes through.
//
// The splitter, the explicit slide form and, at M9, the machine surface all
// produce one, so a malformed slide fails where it is built rather than where
// it is drawn. Only the accepting half is asserted here: every rejection is a
// tests/expect-fail/ case, because Typst cannot catch a panic.

#import "../../src/core/record.typ": check-attrs, default-attrs, slide-record

// ---------------------------------------------------------------------------
// Every key comes back as it went in.
// ---------------------------------------------------------------------------

#let full = slide-record(
  [body],
  kind: "section",
  title: [Title],
  title-source: "heading",
  level: 1,
  label: <slide>,
  attrs: (smaller: true),
)
#assert.eq(full.kind, "section")
#assert.eq(full.title, [Title])
#assert.eq(full.title-source, "heading")
#assert.eq(full.level, 1)
#assert.eq(full.label, <slide>)
#assert.eq(full.attrs, (appendix: false, smaller: true, steps: none))
#assert.eq(full.body, [body])

// The key set is fixed, so a reader never guesses whether a key is there.
#assert.eq(
  full.keys().sorted(),
  ("attrs", "body", "kind", "label", "level", "title", "title-source"),
)

// ---------------------------------------------------------------------------
// Defaults.
//
// A slide with no heading is a content slide whose title is none, so there is
// no third kind. `label` follows `title`: with no heading there is nothing to
// carry a label.
// ---------------------------------------------------------------------------

#let bare = slide-record([body])
#assert.eq(bare.kind, "content")
#assert.eq(bare.title, none)
#assert.eq(bare.title-source, none)
#assert.eq(bare.level, none)
#assert.eq(bare.label, none)
#assert.eq(bare.body, [body])

// An empty body is legitimate: a heading with nothing under it is a slide.
#assert.eq(slide-record([], title: [T], title-source: "heading", level: 2).body, [])

// A title and its source are written together. Which of the two a title came
// from is a property of how the slide was written, not something a reader can
// work out afterwards: a heading opening a slide is that slide's title, while a
// title passed to `slide(...)` is an argument and the body may carry a heading
// of its own at the same level.
#assert.eq(slide-record([], title: [T], title-source: "value", level: 2).title-source, "value")

// ---------------------------------------------------------------------------
// Attributes.
//
// The vocabulary carries only the options something reads, growing as the code
// that reads them lands, which is the rule src/theme/tokens.typ states for
// tokens. `smaller` is the one option page emission reads.
// ---------------------------------------------------------------------------

// Every record carries the full option set, so a reader never repeats a
// default that could then drift from the one declared here.
#assert.eq(bare.attrs, default-attrs())
#assert.eq(default-attrs(), (appendix: false, smaller: false, steps: none))

// An option given fills its own key and leaves the rest at their defaults.
#assert.eq(
  slide-record([body], attrs: (smaller: true)).attrs,
  (appendix: false, smaller: true, steps: none),
)

// `check-attrs` is what the slide-options marker validates through, so a
// mistyped option fails where it is written rather than where it is read.
#check-attrs((:), "slide-options")
#check-attrs((smaller: false), "slide-options")

record tests passed.
