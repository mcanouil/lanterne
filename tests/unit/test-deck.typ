// Page emission: records become pages, styled from the theme alone.
//
// `deck` is written as `#show: deck.with(...)`, which is the same function
// applied to the same body, so the decks below are called directly. Their pages
// are concatenated into this one document, and the count is read at the end
// with `counter(page).final()`, which is what a slide count cannot check: a
// spurious blank page between two slides passes every structural assertion in
// tests/unit/test-slides.typ.

#import "../../src/core/registry.typ": register-container
#import "../../src/core/slides.typ": slide, slide-options
#import "../../src/core/steps.typ": focus, only, pause
// `_heading-size` is private and is read here anyway: inside a `show heading`
// rule the size it produces has not been applied yet, so the scale cannot be
// observed from a rendered heading.
#import "../../src/render/deck.typ": _heading-size, deck
#import "../../src/theme/theme.typ": theme-tokens

// One page per slide: a section slide and two content slides.
#deck([= Section
== A
a
== B
b])

// The same body with heading splitting disabled is one slide, so one page.
#deck(
  [= Section
== A
a
== B
b],
  slide-level: 0,
)

// An explicit page break opens a slide, so it opens a page.
#deck([a #pagebreak() b])

// An explicit slide is a page of its own.
#deck([#slide(title: [T])[x]])

// The page is dressed by the theme rather than by Typst's defaults, and the
// assertions read what the page resolved to rather than what was passed in.
#deck(
  [== Themed
  #context {
    assert.eq(page.fill, rgb("#102030"))
    assert(calc.abs(page.width / page.height - 4 / 3) < 0.01)
    assert.eq(text.size, 30pt)
    assert.eq(text.fill, white)
  }],
  theme: theme-tokens(bg: rgb("#102030"), fg: white, size-base: 30pt),
  aspect-ratio: "4-3",
)

// `smaller` divides the slide's text size by the theme's scale ratio, and only
// that slide's: the option is per slide, not per deck.
#deck([== Small
#slide-options(smaller: true)
#context assert.eq(text.size, 24pt / 1.2)])

// The heading scale is taken from the slide's own base size rather than the
// theme's, so a slide set smaller shrinks its title with its body. A slide that
// asked for room and kept its title exactly as large has not been given much.
//
// Read from the helper rather than from a rendered heading: inside a `show
// heading` rule the size this sets has not been applied yet, so the rule cannot
// observe what it is about to produce.
#let tokens = theme-tokens()
#assert.eq(_heading-size(2, 24pt, tokens), 24pt * 1.2)
#assert.eq(_heading-size(2, 20pt, tokens), 20pt * 1.2)
#assert.eq(_heading-size(3, 24pt, tokens), 24pt)
#assert.eq(_heading-size(1, 24pt, tokens), 24pt * 1.2 * 1.2)

// The author's own rules reach the slide's title, because the title is the
// heading they wrote, left where they wrote it. Lifting it out and re-emitting
// it beside the wrappers would silently take away the `show` rule, the
// numbering and the destination a reference resolves to, and no equality
// assertion could notice.
#deck([#show heading: it => [#it.body #metadata("reached") <rule-reached>]
== Titled
body])

// A reference into a slide resolves, which is the capability the record's label
// is carried for. Typst refuses a reference to an unnumbered heading, so the
// numbering rule is part of the test rather than incidental to it.
#deck([#set heading(numbering: "1.")
== Referenced <slide-ref>
@slide-ref])

// A pause makes a slide render one page per step, so total pages exceed slide
// count. Three pages here: two for the first slide and one for the second.
#let stepped = [== One
a #pause b
== Two
c]
#deck(stepped)

// handout: true collapses every slide to its final step, so the same body is
// two pages, one per slide.
#deck(stepped, handout: true)

// A handout range selects steps by the same parser a step range uses, so a
// slide of three steps rendered as "1-2" is two pages.
#deck([== Selected
a #pause b #pause c], handout: "1-2")

// dim-region reads dim-opacity the right way round: reversing the mapping to
// transparentize(tokens.dim-opacity) would still pass every other test here,
// since every other one leaves dim-opacity at its default. handout: "1" pins
// the rendered step to the one guaranteed dimmed by focus's own before state.
#deck(
  [== Dimmed
  #focus("3", [
    #context assert.eq(text.fill, rgb("#1122339e"))
  ])],
  theme: theme-tokens(fg: rgb("#112233"), dim-opacity: 62%),
  handout: "1",
)

// registry threading is not the wrong-type guard alone: dropping registry:
// registry from the expand call inside deck breaks a step written inside a
// container of the author's own while failing no other test. math.cancel is
// not one of the built in containers, so this only resolves once registered.
#let registered = register-container(math.cancel, ("body",))
#deck(
  [== Registered
  $ #math.cancel(only("2", [x <registered-mark>])) $],
  registry: registered,
)
// Removed on step 1 and visible on step 2, so the label is found once across
// the whole document rather than on every page or none of them.
#context assert.eq(query(<registered-mark>).len(), 1)

// A theme may be a light and dark pair, and `theme-mode` says which half
// renders. The text fill is asserted rather than the page fill, because the
// page is a call rather than a set rule and its fill is not on the style chain
// the body reads; `set text(fill: ...)` is inside the page body and is.
#deck(
  [== Dark
  #context assert.eq(text.fill, white)],
  theme: (light: theme-tokens(fg: black), dark: theme-tokens(fg: white)),
  theme-mode: "dark",
)

// The default aspect ratio is 16-9, matching what a projector expects.
#deck([== Default
#context {
  assert(calc.abs(page.width / page.height - 16 / 9) < 0.01)
  // Twenty three pages: three, one, two, one, one, one, one, one, then three,
  // two and two from the stepped decks, one from the dimmed deck, two from
  // the registered deck, one from the pair deck, and this one. No deck opens a
  // page it was not asked for, which is what a count catches and a record
  // assertion cannot.
  assert.eq(counter(page).final().first(), 23)
  // The author's `show heading` rule ran on the slide's title, which is only
  // possible because the title is still the heading they wrote.
  assert.eq(query(<rule-reached>).len(), 1)
}])
