// A document body becomes slide records, one assertion per rule of
// specification section 4.1.
//
// Two rules fall out of the splitter rather than being coded here, and both are
// asserted anyway: a rule that falls out today can stop falling out tomorrow.
//
// Bodies are compared by concatenation rather than markup, as
// tests/unit/test-split.typ does, because the whitespace either side of a
// boundary belongs to the segments beside it.

#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/slides.typ": slide, slide-options, slides
#import "../../src/utils/elements.typ": STYLED

#let h1 = heading(level: 1)[Section]
#let h2 = heading(level: 2)[Slide]
#let h3 = heading(level: 3)[Inner]

// ---------------------------------------------------------------------------
// Heading levels against slide-level.
// ---------------------------------------------------------------------------

// A heading at slide-level starts a content slide and becomes its title.
#let at-level = slides([#h2 body])
#assert.eq(at-level.len(), 1)
#assert.eq(at-level.first().kind, "content")
#assert.eq(at-level.first().title, [Slide])
#assert.eq(at-level.first().level, 2)

// The heading stays at the head of the slide's body rather than being lifted
// out of it. Lifting it out takes it away from the wrappers it was written
// under, and with them the document's own numbering, its `show heading` rule
// and the destination a reference resolves to. `title` describes it; `body` is
// what renders.
#assert.eq(at-level.first().body, h2 + [ ] + [body])
#assert.eq(at-level.first().body.children.first(), h2)

// The wrappers a deck receives keep the heading inside them, which is the whole
// reason it stays put.
#let under-rule = slides([#set text(size: 10pt)
#h2 body]).first()
#assert.eq(under-rule.body.func(), STYLED)
#assert.eq(under-rule.body.child.children.first(), h2)

// A heading below slide-level starts a section slide.
#let below = slides([#h1 body])
#assert.eq(below.first().kind, "section")
#assert.eq(below.first().title, [Section])
#assert.eq(below.first().level, 1)

// A heading above slide-level is ordinary in-slide content, so it opens no
// slide and stays in the body it was written in.
#let above = slides([#h2 a #h3 b])
#assert.eq(above.len(), 1)
#assert(above.first().body.children.any(child => child.func() == heading))

// slide-level defaults to 2, matching Quarto's Reveal.js default.
#assert.eq(slides([#h2 body]).len(), slides([#h2 body], slide-level: 2).len())
#assert.eq(slides([#h1 a #h2 b], slide-level: 1).len(), 1)

// slide-level: 0 disables heading splitting, so only explicit breaks apply.
#let no-split = slides([#h1 a #h2 b], slide-level: 0)
#assert.eq(no-split.len(), 1)
#assert.eq(no-split.first().title, none)
#assert.eq(no-split.first().kind, "content")

// The markup form of a heading carries `depth` where the function form carries
// `level`, so a splitter reading either name alone fails on half the decks it
// meets.
#assert.eq(slides([intro
== A
body]).len(), 2)
#assert.eq(slides([intro
== A
body]).last().level, 2)

// ---------------------------------------------------------------------------
// Slides with no heading.
// ---------------------------------------------------------------------------

// Content before the first heading forms an implicit untitled slide.
#let lead-in = slides([intro #h2 body])
#assert.eq(lead-in.len(), 2)
#assert.eq(lead-in.first().title, none)
#assert.eq(lead-in.first().kind, "content")
#assert.eq(lead-in.first().body, [intro] + [ ])

// It is dropped when it is visually empty, and only then. Whitespace, a
// paragraph break and a marker are all invisible.
#assert.eq(slides([#h2 body]).len(), 1)
#assert.eq(slides([ #h2 body]).len(), 1)
#assert.eq(slides([#marker(MARKER-PAUSE) #h2 body]).len(), 1)
#assert.eq(slides([

#h2 body]).len(), 1)

// A document with no heading at all is one untitled slide.
#assert.eq(slides([just content]).len(), 1)
#assert.eq(slides([just content]).first().body, [just content])

// A document with nothing visible in it is no slides at all.
#assert.eq(slides([]).len(), 0)
#assert.eq(slides([ ]).len(), 0)

// ---------------------------------------------------------------------------
// Explicit breaks.
// ---------------------------------------------------------------------------

// A pagebreak at body top level starts a new slide with no title. It is what
// the author asked for, so it opens a slide even where nothing follows it.
#let broken = slides([#h2 a #pagebreak() b])
#assert.eq(broken.len(), 2)
#assert.eq(broken.last().title, none)
#assert.eq(broken.last().body, [ ] + [b])
#assert.eq(slides([#h2 a #pagebreak()]).len(), 2)

// An explicit slide is a complete slide and is not merged with the content
// around it: what precedes it closes, and what follows it opens a new slide.
#let explicit = slides([before #slide(title: [T], level: 2)[inside] after])
#assert.eq(explicit.len(), 3)
#assert.eq(explicit.at(0).title, none)
#assert.eq(explicit.at(1).title, [T])
#assert.eq(explicit.at(1).body, [inside])
#assert.eq(explicit.at(2).title, none)
#assert.eq(explicit.at(2).body, [ ] + [after])

// Nothing but the explicit slide is one slide, so the empty space around it
// does not become slides of its own.
#assert.eq(slides([#slide[only]]).len(), 1)

// An explicit slide takes its level from the deck when it names a title and no
// level, since a slide of the author's own sits where the deck's slides sit.
#assert.eq(slides([#slide(title: [T])[body]]).first().level, 2)
#assert.eq(slides([#slide(title: [T])[body]], slide-level: 3).first().level, 3)
#assert.eq(slides([#slide[body]]).first().level, none)

// A deck that splits on no heading at all still has to give an explicit slide's
// title a level a heading could be written at, so the level floors at 1 rather
// than taking the 0 that disables splitting.
#assert.eq(slides([#slide(title: [T])[body]], slide-level: 0).first().level, 1)
#assert.eq(slides([#slide(title: [T])[body]], slide-level: 0).len(), 1)

// An explicit slide takes its options as arguments.
#assert.eq(slides([#slide(title: [T], smaller: true)[body]]).first().attrs.smaller, true)

// ---------------------------------------------------------------------------
// Rules that fall out of the splitter, pinned so that they stay decisions.
// ---------------------------------------------------------------------------

// A section heading immediately followed by a content heading emits a section
// slide and then a content slide, with no empty slide between them.
#let adjacent = slides([#h1 #h2 body])
#assert.eq(adjacent.len(), 2)
#assert.eq(adjacent.first().kind, "section")
#assert.eq(adjacent.last().kind, "content")

// A heading with no following content still emits a slide, because a
// title-only slide is legitimate.
#let title-only = slides([#h2])
#assert.eq(title-only.len(), 1)
#assert.eq(title-only.first().title, [Slide])

// A heading nested inside a container never splits, because it is not a top
// level child. Documented rather than worked around.
#assert.eq(slides([#h2 a #block[#h2 b] c]).len(), 1)

// A heading that arrived as one value does split, because that is what an
// `#include`, a `#let` fragment or a helper's return value looks like, and a
// deck written across several files is the ordinary case.
#let part = [#h2 from another file]
#assert.eq(slides([#h2 a #part]).len(), 2)
#assert.eq(slides([#h2 a #part]).last().title, [Slide])

// ---------------------------------------------------------------------------
// The three ways a heading reports its level.
// ---------------------------------------------------------------------------

// `heading(offset: 1)` carries neither `level` nor `depth`, since the depth it
// is added to is the default of 1, so its real level is 2 and it opens a slide.
#assert.eq(slides([#heading(offset: 1)[Offset] body]).len(), 1)
#assert.eq(slides([#heading(offset: 1)[Offset] body]).first().level, 2)
#assert.eq(slides([#heading(offset: 1)[Offset] body]).first().title, [Offset])

// An offset set by a rule is not reachable. It lives in the style wrapper, and
// Typst exposes no way to read a wrapper's rules, so the heading is split at
// the level it was written at rather than the level it renders at. Pinned so
// the limitation is a decision rather than a surprise.
#let offset-by-rule = slides([#set heading(offset: 1)
= Written as one
body]).first()
#assert.eq(offset-by-rule.level, 1)
#assert.eq(offset-by-rule.kind, "section")

// ---------------------------------------------------------------------------
// Per-slide options.
// ---------------------------------------------------------------------------

// The marker is consumed by the splitter and never rendered, and its payload
// becomes the record's options.
#let optioned = slides([#h2
#slide-options(smaller: true)
body])
#assert.eq(optioned.len(), 1)
#assert.eq(optioned.first().attrs.smaller, true)
#assert(not optioned.first().body.children.any(child => child.func() == metadata))

// A slide that names no option still carries the full option set at its
// defaults, so nothing downstream repeats a default.
#assert.eq(slides([#h2 body]).first().attrs.smaller, false)

// Options attach to an untitled slide too, since a slide with no heading is
// still a slide.
#assert.eq(slides([#slide-options(smaller: true)
body]).first().attrs.smaller, true)

// ---------------------------------------------------------------------------
// What the deck actually receives.
//
// `#show: deck.with(...)` hands the function a styled element whenever the
// document sets anything after that line, so every rule above has to hold
// through the wrapper as well.
// ---------------------------------------------------------------------------

#let ruled = [#set text(size: 10pt)
intro #h2 a #h1 b]
#assert.eq(slides(ruled).len(), 3)
#assert.eq(slides(ruled).at(1).title, [Slide])
#assert.eq(slides(ruled).at(2).kind, "section")

// ---------------------------------------------------------------------------
// Labels.
//
// A labelled heading is how a cross reference into a slide resolves, and
// content equality ignores labels, so no equality assertion above could notice
// one being dropped. These read the field.
// ---------------------------------------------------------------------------

#let labelled = slides([== A <lbl>
body])
#assert.eq(labelled.len(), 1)
#assert.eq(labelled.first().label, <lbl>)
#assert.eq(labelled.first().title, [A])

// A heading with no label carries none rather than a label of its own making.
#assert.eq(slides([#h2 body]).first().label, none)

slides tests passed.
