// The registry must cover the wrappers Quarto emits, or the Lua filter that
// drives lanterne from a .qmd cannot work. Every shape asserted below is
// transcribed from tests/fixtures/quarto-deck.typ, which Quarto 1.9.38
// generated from tests/fixtures/quarto-deck.qmd.
//
// The fixture itself is not compiled here. It imports @preview/fontawesome,
// and lanterne carries no runtime dependency, so the shapes are reproduced
// rather than loaded. Regenerate the fixture when Quarto changes and read it
// again; never hand edit it.
//
// The distinction this file exists to pin down is that Quarto's preamble
// defines Typst *functions*, and a function is not an element. Calling one
// returns content already built from ordinary elements, so the traversal
// never meets the function and no registry entry is needed for it. Only the
// built in elements it produced need entries.
//
// Typst memoises a call, so an equality routed through a shared helper call
// site proves nothing. Every assertion below is written inline.

#import "../../src/core/marker.typ": MARKER-PAUSE, marker
#import "../../src/core/registry.typ": lookup
#import "../../src/core/split.typ": split-on
#import "../../src/core/walk.typ": has-marker, rebuild

#let m = marker(MARKER-PAUSE)
// Adjacent text merges into a single element, so a plain text substitution
// would make the rebuilt sequence unequal to the markup written beside it
// for reasons that have nothing to do with the traversal. Substituting an
// element that never merges keeps every assertion about the rebuild.
#let sub = node => [*z*]

// ---------------------------------------------------------------------------
// Elements Quarto emits directly.
// ---------------------------------------------------------------------------

// Every fenced div becomes a plain block. Both the `.column` width and the
// `.incremental` class are dropped on the way, which is why the follow up
// needs a filter of its own and cannot read the class from the Typst output.
#assert(has-marker(block[#m]))
#assert.eq(rebuild(block[#m], sub), block[*z*])

// A section heading carries the crossref label of its slide. The label is not
// a constructor parameter, so it is the rebuild that has to reattach it.
#let head = [#heading(level: 1)[Columns #m]
<columns>].children.first()
#assert.eq(head.label, <columns>)
#assert(has-marker(head))

#let rebuilt-head = rebuild(head, sub)
#assert.eq(rebuilt-head.label, <columns>)
#assert.eq(rebuilt-head, heading(level: 1)[Columns *z*])

// A bullet list, the shape an `.incremental` div wraps.
#assert.eq(rebuild(list([One.], [Two. #m]), sub), list([One.], [Two. *z*]))

// The float Quarto emits for a crossreferenced figure: an explicit caption
// element with a position, a string kind, a supplement, and a trailing label.
#let fig = [#figure(
    [A body. #m],
    caption: figure.caption(position: bottom, [A one pixel square.]),
    kind: "quarto-float-fig",
    supplement: "Figure",
  )
<fig-square>].children.first()
#assert.eq(fig.label, <fig-square>)
#assert(has-marker(fig))

#let rebuilt-fig = rebuild(fig, sub)
#assert.eq(rebuilt-fig.label, <fig-square>)
#assert.eq(
  rebuilt-fig,
  figure(
    [A body. *z*],
    caption: figure.caption(position: bottom, [A one pixel square.]),
    kind: "quarto-float-fig",
    supplement: "Figure",
  ),
)

// A marker in the caption rather than the body reaches a named field.
#assert.eq(
  rebuild(figure([b], caption: figure.caption(position: top, [c #m])), sub),
  figure([b], caption: figure.caption(position: top, [c *z*])),
)

// The figure body is a boxed image. An image is an opaque leaf, so the
// instance itself has to come back: a faithful copy of it would compare
// unequal, and an equality assertion over the whole figure would fail.
#let svg-bytes = bytes(
  "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\"></svg>",
)
#let img = image(svg-bytes, format: "svg")

// The marker sits inside the box, so the box is rebuilt and the image is
// reached by the opaque-leaf guard. With the marker outside it, the box holds
// no marker and comes back through the generic guard instead, which would
// pass even if the image branch were deleted.
#assert.eq(rebuild(box[#img#m], sub).body.children.first(), img)

// A reference to that float. Its target is a label rather than content, but
// its supplement is content, so the entry for `ref` is load bearing.
#assert(not has-marker(ref(<fig-square>, supplement: [Figure])))
#assert.eq(
  rebuild(ref(<fig-square>, supplement: [#m]), sub),
  ref(<fig-square>, supplement: [*z*]),
)

// A Markdown table. `table.header` is emitted for every table with a header
// row and was the one registry gap this fixture found; see the entry added
// after the spike in docs/notes/roundtrip-findings.md. `table.hline` takes no
// content, so it can never carry a marker and needs no entry.
#assert.eq(
  rebuild(
    table(
      columns: 2,
      align: (auto, auto),
      table.header([Left #m], [Right]),
      table.hline(),
      [a], [b],
    ),
    sub,
  ),
  table(
    columns: 2,
    align: (auto, auto),
    table.header([Left *z*], [Right]),
    table.hline(),
    [a], [b],
  ),
)

// A definition list, which the preamble reaches with `show terms.item`.
#assert.eq(
  rebuild(terms(terms.item([Term], [The definition. #m])), sub),
  terms(terms.item([Term], [The definition. *z*])),
)

// A block quotation and a block equation.
#assert.eq(
  rebuild(quote(block: true)[A quotation. #m], sub),
  quote(block: true)[A quotation. *z*],
)
#assert.eq(
  rebuild(math.equation(block: true)[#m], sub),
  math.equation(block: true)[*z*],
)

// Inline markup.
#assert.eq(rebuild(emph[#m], sub), emph[*z*])
#assert.eq(rebuild(strong[#m], sub), strong[*z*])
#assert.eq(
  rebuild(link("https://example.com")[#m], sub),
  link("https://example.com")[*z*],
)
#assert.eq(
  rebuild(footnote[The footnote body. #m], sub),
  footnote[The footnote body. *z*],
)

// ---------------------------------------------------------------------------
// Functions Quarto defines in its preamble.
//
// These are the cases that decide whether the premise holds. Each definition
// below is transcribed from the fixture, shortened only where the omitted
// parts add no element the traversal has not already met.
// ---------------------------------------------------------------------------

#let callout(
  body: [],
  title: "Callout",
  background_color: rgb("#dddddd"),
  icon: none,
  icon_color: black,
  body_background_color: white,
) = {
  block(
    breakable: false,
    fill: background_color,
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"),
    width: 100%,
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%,
      below: 0pt,
      block(fill: background_color, width: 100%, inset: 8pt)[
        #if icon != none [#text(icon_color, weight: 900)[#icon] ]#title
      ],
    )
      + if body != [] {
        block(
          inset: 1pt,
          width: 100%,
          block(
            fill: body_background_color,
            width: 100%,
            inset: 8pt,
            body,
          ),
        )
      },
  )
}

#let noted = callout(
  body: [A note. #m],
  title: [Note],
  background_color: rgb("#dae6fb"),
  icon_color: rgb("#0758E5"),
  body_background_color: white,
)

// There is no callout element and there never was one: by the time the
// traversal runs, the call has already returned a block. This is why a
// user defined function needs no registry entry, and the assertion that it
// has none is what makes the point rather than assumes it.
#assert.eq(noted.func(), block)
#assert.eq(lookup(callout), none)

#assert(has-marker(noted))
#assert.eq(
  rebuild(noted, sub),
  callout(
    body: [A note. *z*],
    title: [Note],
    background_color: rgb("#dae6fb"),
    icon_color: rgb("#0758E5"),
    body_background_color: white,
  ),
)

// The syntax highlighting helpers, which turn a code block into an array of
// content lines. Setting a text property never yields a text element, so each
// token is a styled element wrapping a raw one.
#let NormalTok(s) = text(fill: rgb("#003b4f"), raw(s))
#let EndLine() = raw("\n")
#let Skylighting(sourcelines) = {
  let blocks = []
  for ln in sourcelines {
    blocks = blocks + ln + EndLine()
  }
  block(fill: rgb("#f1f3f5"), width: 100%, inset: 8pt, radius: 2pt, blocks)
}

#assert.eq(NormalTok("mean").func(), text(size: 12pt)[x].func())

// The marker sits inside an array of content, which the traversal walks
// without needing an element to hang it on.
#assert(has-marker(Skylighting(([#NormalTok("mean(") #m #NormalTok(")")],))))
#assert.eq(
  rebuild(Skylighting(([#NormalTok("mean(") #m #NormalTok(")")],)), sub),
  Skylighting(([#NormalTok("mean(") *z* #NormalTok(")")],)),
)

// The title block of the `article` template: a floating place with a parent
// scope, whose alignment is positional alongside its body.
#assert.eq(
  rebuild(
    place(top, float: true, scope: "parent", clearance: 4mm, block(
      below: 1em,
      width: 100%,
    )[#m]),
    sub,
  ),
  place(top, float: true, scope: "parent", clearance: 4mm, block(
    below: 1em,
    width: 100%,
  )[*z*]),
)

// The author grid of the same template.
#assert.eq(
  rebuild(
    grid(columns: (1fr, 1fr), row-gutter: 1.5em, align(center)[#m], [b]),
    sub,
  ),
  grid(columns: (1fr, 1fr), row-gutter: 1.5em, align(center)[*z*], [b]),
)

// ---------------------------------------------------------------------------
// The callout rewrite is a `show figure` rule, so the traversal can be reached
// from inside one. A figure synthesised there gains a `counter` field that is
// not a constructor parameter and has to be dropped.
// ---------------------------------------------------------------------------

#show figure: it => {
  assert("counter" in it.fields())
  assert.eq(rebuild(it, node => node), it)
  []
}

#figure(
  [A body. #m],
  caption: figure.caption(position: bottom, [c]),
  kind: "quarto-float-fig",
  supplement: "Figure",
)

// Both committed floats are captioned, so a marker in a caption is the shape
// this fixture actually emits. Inside a show rule the caption synthesises
// `kind`, `supplement`, `numbering` and `counter`, none of them constructor
// parameters, and the body-only case above never reaches them.
#figure(
  [A body.],
  caption: figure.caption(position: bottom, [c #m]),
  kind: "quarto-float-fig",
  supplement: "Figure",
)

// ---------------------------------------------------------------------------
// The preamble's rules, which decide whether a generated deck can be split at
// all. The fixture opens with `#show terms.item`, `#show raw.where(block:
// true): set block`, `#set table` and `#set page` before the first heading,
// and each of them wraps everything after it in a styled element.
//
// This is the shape a deck receives in practice, because the extension's
// template replaces the fixture's `#show: doc => article(...)` with
// `#show: deck.with(...)`, and every rule written after that line reaches the
// deck function as a wrapper around the body rather than as a sibling of it.
// ---------------------------------------------------------------------------

#let is-h1 = node => {
  if type(node) != content or node.func() != heading { return false }
  let fields = node.fields()
  fields.at("depth", default: fields.at("level", default: none)) == 1
}

#let generated = [
  #show terms.item: it => block(breakable: false)[#it]
  #show raw.where(block: true): set block(width: 100%, inset: 8pt)
  #set table(stroke: none)
  #set page(width: 8.5in, height: 11in)

  = Columns
  Left. Right.

  = Incremental
  One. Two.

  = Callout
  A note.
]

#assert.eq(split-on(generated, is-h1).len(), 4)

// The preamble sets the page, so a segment count alone is not enough: the
// styles have to go back on around a whole run rather than around each child,
// or every child of this body opens a page group of its own and the deck
// renders one page per element while this count still reads 4.
#assert.eq(split-on(generated, _ => false).first(), generated)

quarto fixture tests passed.
