// The two built in themes.
//
// `plain` is the canonical defaults and no slots, and it is what a deck naming
// no theme gets. `banded` composes a page rather than only dressing one, which
// is the specification's own justification for the slots existing: two presets
// that differed only in colour would prove nothing about them.

#import "../../src/core/slides.typ": slide
#import "../../src/render/deck.typ": deck
#import "../../src/theme/presets.typ": theme-banded, theme-default, theme-plain
#import "../../src/theme/theme.typ": resolve-mode, theme-merge, theme-tokens
#import "../../src/theme/tokens.typ": SLOT-NAMES

// `plain` is the canonical defaults exactly, as a value rather than as a
// rendering. `deck` takes it when no theme is named, so the two have to be the
// same thing: asserting it here is what lets the visual goldens stand as
// corroboration rather than as the whole proof.
// Asserted against the value a themeless deck actually reads, which is the
// claim that matters. `theme-plain() == theme-tokens()` cannot fail, since one
// is defined as the other, so it says nothing on its own; the path `deck` takes
// does not go through `theme-tokens` at all.
#assert.eq(resolve-mode(none, "light", "test").tokens, theme-plain())
#assert.eq(theme-plain(), theme-tokens())
#assert.eq(theme-default(), theme-plain())
#assert.eq(theme-plain().slots, (:))

// A preset takes overrides, so a deck adopts one and changes what it likes
// without rebuilding it.
#assert.eq(theme-plain(bg: black).bg, black)
#assert.eq(theme-banded(accent: red).accent, red)

// `banded` composes: a header for the title, a footer, and a section slide of
// its own. It supplies no progress region, since a progress indicator reads a
// position in the deck that nothing reports yet.
#assert.eq(
  theme-banded().slots.keys().sorted(),
  ("render-footer", "render-header", "render-section-slide"),
)
#assert(theme-banded().slots.keys().all(name => name in SLOT-NAMES))

// Overriding a colour keeps the renderers, which is what merging a reserved key
// key by key is for.
#let louder = theme-merge(theme-banded(), (accent: red))
#assert.eq(louder.accent, red)
#assert.eq(louder.slots.keys().len(), 3)

// A theme takes another's chrome minus one part by clearing a slot.
#assert.eq(theme-merge(theme-banded(), (slots: (render-footer: none))).slots.keys().len(), 2)

// `banded`'s header declines a slide with no title rather than placing nothing,
// which is what the placement guard requires of any header.
#let header = theme-banded().slots.render-header
#assert.eq(
  header(
    info: (:),
    tokens: theme-banded(),
    state: (
      kind: "content",
      title: none,
      title-source: none,
      level: none,
      appendix: false,
      body: [],
      step: (index: 1, total: 1),
      mode: "light",
    ),
  ),
  none,
)

// A deck under each preset renders, which is the assertion that catches a slot
// whose body only fails once something calls it.
#deck([== Plain <preset-plain>

body], theme: theme-plain())
#deck([= A section

== Banded <preset-banded>

body], theme: theme-banded(), slide-level: 2)
#deck([#pagebreak()

untitled <preset-untitled>], theme: theme-banded())
#context {
  assert.eq(query(<preset-plain>).len(), 1)
  assert.eq(query(<preset-banded>).len(), 1)
  assert.eq(query(<preset-untitled>).len(), 1)
}

// A title passed to `slide(...)` is not a heading, so no `show heading` rule
// reaches it and the theme sets the heading font and size itself. Wrapping it in
// `heading(...)` instead would mint a second heading, which numbers, outlines
// and bookmarks, and so would put an explicit slide in the outline it was never
// in. One heading on the page is the assertion that catches it.
#deck([#slide(title: [An argument])[body <preset-value>]], theme: theme-banded())
#context {
  assert.eq(query(<preset-value>).len(), 1)
  assert.eq(query(heading).filter(it => it.body == [An argument]).len(), 0)
}

preset tests passed.
