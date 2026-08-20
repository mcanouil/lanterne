// The five renderer slots, wired.
//
// A theme composes a page from regions rather than dressing one body, and the
// slide's title becomes a value a slot can place. Everything the correctness
// milestone settled has to survive that move: a title numbers once per slide
// rather than once per step, is listed once in the outline, is bookmarked by
// the rules of specification 4.7, and a reference to it still resolves.
//
// Each deck below is its own document counter, so the page counts here are
// local to this file.

#import "../../src/core/slides.typ": appendix, slide
#import "../../src/core/steps.typ": pause
#import "../../src/render/deck.typ": _regions, deck
#import "../../src/theme/theme.typ": theme-tokens

// A theme that places the title in a header region and nothing else.
#let headed = theme-tokens(
  slots: (render-header: (info: none, tokens: none, state: none) => state.title),
)

// The title renders in the header, out of the body, and is still the heading
// the author wrote: numbered, outlined, and a reference destination.
#deck(
  [#set heading(numbering: "1.")
  == Titled <slot-title>

  body],
  theme: headed,
)
// `query` sees the whole document, and this file renders many decks, so every
// assertion below names the slide it is about rather than counting globally.
#let titles(body) = query(heading).filter(it => it.body == body)

#context {
  assert.eq(query(<slot-title>).len(), 1)
  assert.eq(titles([Titled]).len(), 1)
}

// A `show heading` rule written by the author reaches the title after it has
// been moved into the header. This is the M3 ruling, which the move could
// silently undo: the rule lives in a style wrapper, and `split-head` carries
// that wrapper with the title.
#deck(
  [#show heading: it => [seen #it.body]
  == Restyled <slot-restyled>

  body],
  theme: headed,
)
#context assert.eq(query(<slot-restyled>).len(), 1)

// The correctness rules of M5 survive the move. A three step slide renders
// three pages, and its title is numbered once, listed once and bookmarked by
// its kind rather than once per page. Without `_chrome` wrapping the whole
// composed page, the title would escape all three.
#deck(
  [#set heading(numbering: "1.")
  == Stepped <slot-stepped>

  first
  #pause
  second
  #pause
  third],
  theme: headed,
)
#context {
  // One entry for three pages. Without the suppression wrapping the composed
  // page this would be three.
  assert.eq(titles([Stepped]).filter(it => it.outlined).len(), 1)
  // A content slide is not a bookmark, per specification 4.7, whichever region
  // its title renders in.
  assert(titles([Stepped]).all(it => it.bookmarked == false))
  assert.eq(query(<slot-stepped>).len(), 1)
}

// A section slide composes through its own slot, which replaces the centred
// default rather than filling a region of it.
#let sectioned = theme-tokens(
  slots: (render-section-slide: (info: none, tokens: none, state: none) => [
    #state.title
    #state.body
  ]),
)
#deck(
  [= A section <slot-section>

  under it

  == A slide

  body],
  theme: sectioned,
  slide-level: 2,
)
#context {
  assert.eq(query(<slot-section>).len(), 1)
  // A section heading is a bookmark and a content heading is not, which the
  // slot composing the page does not change.
  assert(titles([A section]).first().bookmarked != false)
  assert.eq(titles([A slide]).first().bookmarked, false)
}

// An appendix slide rendered through the section slot is neither outlined nor
// bookmarked, since the suppression wraps whatever the slot composed.
#deck(
  [= Before <slot-before>

  == One

  body

  #appendix

  = After <slot-after>

  == Two

  body],
  theme: sectioned,
  slide-level: 2,
)
#context {
  let outlined = query(heading).filter(it => it.outlined)
  assert.eq(outlined.filter(it => it.body == [After]).len(), 0)
  assert.eq(outlined.filter(it => it.body == [Before]).len(), 1)
}

// The state a slot receives reports the step's place in the slide's whole step
// space, which is what a range is written against.
#let seen = state("slot-steps", ())
#let recording = theme-tokens(
  slots: (
    render-header: (info: none, tokens: none, state: none) => {
      seen.update(it => it + ((state.step.index, state.step.total),))
      state.title
    },
  ),
)
#deck(
  [== Steps

  one
  #pause
  two],
  theme: recording,
)
#context assert.eq(seen.final(), ((1, 2), (2, 2)))

// A handout reports the step it kept rather than renumbering it, so a slot
// showing progress says which step of the slide it is showing.
#let kept = state("slot-handout", ())
#let handing = theme-tokens(
  slots: (
    render-header: (info: none, tokens: none, state: none) => {
      kept.update(it => it + ((state.step.index, state.step.total),))
      state.title
    },
  ),
)
#deck(
  [== Handed

  one
  #pause
  two],
  theme: handing,
  handout: true,
)
#context assert.eq(kept.final(), ((2, 2),))

// An explicit slide carries a title and no heading, so nothing is taken out of
// its body and the record's own copy is placed instead. `title-source` is what
// tells a theme the difference, since the value is not a heading and no
// `show heading` rule reaches it.
#let sourced = state("slot-source", ())
#let sourcing = theme-tokens(
  slots: (
    render-header: (info: none, tokens: none, state: none) => {
      sourced.update(it => it + (state.title-source,))
      state.title
    },
  ),
)
#deck(
  [== Written

  body

  #slide(title: [Explicit])[its body]],
  theme: sourcing,
)
#context assert.eq(sourced.final(), ("heading", "value"))

// An explicit slide's body may legitimately carry a heading at the deck's own
// level, since nothing splits that body. The title is the argument the author
// wrote, not the first heading inside it: taking the heading would discard the
// argument and delete the heading from the body at the same time.
#let taken = state("slot-explicit", ())
#let capturing = theme-tokens(
  slots: (
    render-header: (info: none, tokens: none, state: none) => {
      taken.update(it => it + ((state.title, state.title-source),))
      state.title
    },
  ),
)
#deck(
  [#slide(title: [Argument])[
    == Inside <slot-inside>

    body
  ]],
  theme: capturing,
)
#context {
  assert.eq(taken.final(), (([Argument], "value"),))
  // The heading stays in the body, where the author put it.
  assert.eq(query(<slot-inside>).len(), 1)
}

// A theme that places no title leaves the body whole. Taking a title out with
// nowhere to put it would delete it from the slide.
#let footed = theme-tokens(
  slots: (render-footer: (info: none, tokens: none, state: none) => [foot]),
)
#deck(
  [== Kept <slot-kept>

  body],
  theme: footed,
)
#context assert.eq(query(<slot-kept>).len(), 1)

// A title slide belongs to no record. A heading a theme writes into one is
// neither numbered, outlined nor bookmarked, so the first real slide takes the
// number it would have taken without one.
#let titled = theme-tokens(
  slots: (render-title-slide: (info: none, tokens: none, state: none) => [
    = #info.title
  ]),
)
#deck(
  [#set heading(numbering: "1.")
  == First <slot-first>

  body],
  theme: titled,
  info: (title: [A deck]),
)
#context {
  // The heading the theme wrote into its title slide contributes nothing: not
  // an outline entry, and not a step of the heading counter, so the first real
  // slide numbers as it would without a title slide.
  assert.eq(titles([A deck]).len(), 1)
  assert(titles([A deck]).all(it => not it.outlined))
  assert.eq(titles([First]).first().outlined, true)
  // The number itself, which is the assertion a weaker rule would pass. The
  // theme's title slide writes a level 1 heading; were it merely unbookmarked
  // it would still advance the hierarchical heading counter, and no rewind can
  // put that back. The level 2 count is cumulative over every deck in this
  // file, so the claim is about the level 1 component: it is still zero.
  assert.eq(counter(heading).at(titles([First]).first().location()).first(), 0)
  assert.eq(query(<slot-first>).len(), 1)
}

// A theme that supplies a title slide and deck chrome draws the chrome on its
// slides and not over its own title page. The title page is not a slide of the
// deck, and a region there would receive a `state` describing no slide at all.
#let marks = state("slot-title-page", 0)
#let dressed = theme-tokens(
  slots: (
    render-title-slide: (info: none, tokens: none, state: none) => [a title page],
    render-header: (info: none, tokens: none, state: none) => {
      marks.update(it => it + 1)
      state.title
    },
  ),
)
#deck(
  [== One

  body

  == Two

  body],
  theme: dressed,
  info: (title: [A deck]),
)
// Two slides, so two headers. Three would mean the title page took one.
#context assert.eq(marks.final(), 2)

// A slot may return `none` to say that its region takes no space on this page,
// which is what an absent slot already means. A theme varies its chrome by
// reading `kind`, `appendix` or `step`, so the state it is given invites the
// case.
#let varying = theme-tokens(
  slots: (
    render-footer: (info: none, tokens: none, state: none) => {
      if state.appendix { none } else { [foot] }
    },
  ),
)
#deck(
  [== Body <slot-varying>

  body

  #appendix

  == After

  body],
  theme: varying,
)
#context assert.eq(query(<slot-varying>).len(), 1)

// The progress slot: called once per page like the others, skipped on a section
// slide and on the title page, and sized by what it holds rather than by a
// token, since a progress indicator is a rule a few points high.
#let ticks = state("slot-progress", ())
#let paced = theme-tokens(
  slots: (
    render-title-slide: (info: none, tokens: none, state: none) => [title],
    render-progress: (info: none, tokens: none, state: none) => {
      ticks.update(it => it + ((state.kind, state.step.index),))
      line(length: 100%)
    },
  ),
)
#deck(
  [= A section

  == A slide

  one
  #pause
  two],
  theme: paced,
  slide-level: 2,
  info: (title: [Paced]),
)
// Two pages of the stepped slide, and neither the section slide nor the title
// page, so the section never appears in the record.
#context assert.eq(ticks.final(), (("content", 1), ("content", 2)))

// A title slot that declines emits no page at all, rather than a blank one. The
// natural way to write a conditional title page is to return `none` when there
// is no metadata to build one from, and a stray empty opening page is not what
// that asks for.
#let conditional = theme-tokens(
  slots: (
    render-title-slide: (info: none, tokens: none, state: none) => {
      if info.at("title", default: none) == none { none } else { [a title page] }
    },
  ),
)
anchor #label("slot-anchor")
#deck([== Only <slot-conditional>

body], theme: conditional)
// The slide opens the page straight after the one this file was already on. A
// blank title page would have pushed it one further, and nothing on that page
// would have said why.
#context {
  let anchor = query(<slot-anchor>).first().location().page()
  let slide = query(<slot-conditional>).first().location().page()
  assert.eq(slide, anchor + 1)
}

// A title slot written in markup yields blank content rather than `none`, and
// blank content is the same statement: this deck has no title page. Every other
// slot already reads the two as one thing.
#let markup-conditional = theme-tokens(
  slots: (
    render-title-slide: (info: none, tokens: none, state: none) => [#if false [never]],
  ),
)
markup anchor #label("slot-markup-anchor")
#deck([== Only markup <slot-markup>

body], theme: markup-conditional)
#context {
  let anchor = query(<slot-markup-anchor>).first().location().page()
  let slide = query(<slot-markup>).first().location().page()
  assert.eq(slide, anchor + 1)
}

// A title slot may decline, and composes an empty page when it does. Nothing is
// lost by that: a title page carries no title of the deck's, so there is
// nothing it could fail to place. A section slot that declines is refused
// instead, since a section slide's title always came from a heading, and
// tests/expect-fail/slot-declines-the-section.typ pins it.
#let quiet = theme-tokens(
  slots: (render-title-slide: (info: none, tokens: none, state: none) => none),
)
#deck(
  [#pagebreak()

  untitled body <slot-quiet>],
  theme: quiet,
  info: (title: [Quiet]),
)
#context assert.eq(query(<slot-quiet>).len(), 1)

// The geometry itself, asserted directly. Every structural test above passes
// whatever the rows are, and tests/visual/README.md names this exact risk: a
// theme can validate every argument, pass every test in tests/unit/, and still
// put the title in the wrong place.
#let geometry = theme-tokens(header-height: 3cm, footer-height: 1cm, gutter: 5mm)

// With no region, the body is handed back untouched rather than wrapped in a
// grid of one row.
#assert.eq(_regions(geometry, body: [b]), [b])

// With regions, one row each, in the order they render: header, body,
// progress, footer.
#let full = _regions(
  geometry,
  body: [b],
  header: [h],
  progress: [p],
  footer: [f],
)
#assert.eq(full.func(), grid)
#assert.eq(full.rows, (3cm, 1fr, auto, 1cm))
#assert.eq(full.row-gutter, (5mm,))
#assert.eq(full.children.map(cell => cell.body), ([h], [b], [p], [f]))

// A region whose slot returned blank content takes no row either. Two spellings
// of one intent must give one layout: a conditional written in markup yields
// the blank where the same conditional written in code yields `none`, and every
// other path in the renderer already reads the two as one statement.
#let markup-blank = _regions(geometry, body: [b], footer: [#if false [foot]])
#assert.eq(markup-blank, [b])

// A region a theme did not supply takes no row at all, so the body keeps the
// space rather than a blank band holding it.
#let footer-only = _regions(geometry, body: [b], footer: [f])
#assert.eq(footer-only.rows, (1fr, 1cm))
#assert.eq(footer-only.children.map(cell => cell.body), ([b], [f]))

// A theme branching on `kind` inside its own title renderer is told it is
// composing a title page, not a content slide.
#let kinds = state("slot-kinds", ())
#let branching = theme-tokens(
  slots: (
    render-title-slide: (info: none, tokens: none, state: none) => {
      kinds.update(it => it + (state.kind,))
      [a title page]
    },
    render-header: (info: none, tokens: none, state: none) => {
      kinds.update(it => it + (state.kind,))
      state.title
    },
  ),
)
#deck(
  [= A section

  == A slide

  body],
  theme: branching,
  slide-level: 2,
  info: (title: [Kinds]),
)
// The title page, then the content slide. The section slide has no header.
#context assert.eq(kinds.final(), ("title", "content"))

slot tests passed.
