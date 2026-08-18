// Numbering across the steps of a slide, asserted on the rendered document
// rather than on a record: a counter that re-increments is invisible to every
// structural assertion, because each step's body is the same content whatever
// number it renders with.
//
// The decks are called rather than shown, as in test-deck.typ, so several fit
// in one document and the queries below read all of them.

#import "../../src/core/steps.typ": only, pause
#import "../../src/render/deck.typ": deck

#set math.equation(numbering: "(1)")

// A figure revealed by a pause keeps its number on every step, a figure after
// a region that is dropped on some steps keeps its number too, and the slide
// after them continues from the slide's own total rather than from the
// inflated one.
#deck([
  == Figures
  #only("1", figure(rect(width: 4mm, height: 2mm), caption: [gone]))
  #figure(rect(width: 4mm, height: 2mm), caption: [stays])
  #pause
  #figure(rect(width: 4mm, height: 2mm), caption: [late])

  == After
  #figure(rect(width: 4mm, height: 2mm), caption: [after])
])

// A query reads the whole document rather than the part above it, so each
// assertion below names the captions it is about.
#let numbers-of(names) = {
  query(figure)
    .filter(it => it.caption.body.text in names)
    .map(it => (it.caption.body.text, it.counter.at(it.location()).first()))
}

#context {
  assert.eq(
    numbers-of(("gone", "stays", "late", "after")),
    (
      ("gone", 1),
      ("stays", 2),
      ("late", 3),
      ("stays", 2),
      ("late", 3),
      ("after", 4),
    ),
  )
}

// The same rule for the two other counters a deck advances. An equation is
// counted only because it is block level and numbered, and a footnote is
// counted always.
#deck([
  == Equations and notes
  $ x = 1 $
  a#footnote[first]
  #pause
  $ y = 2 $
  b#footnote[second]
])

#context {
  let equations = query(math.equation).map(it => counter(math.equation).at(it.location()).first())
  let notes = query(footnote).map(it => counter(footnote).at(it.location()).first())
  // Two equations and two footnotes, each numbered the same on both steps.
  assert.eq(equations, (1, 2, 1, 2))
  assert.eq(notes, (1, 2, 1, 2))
}

// A slide of one step is left exactly as it was: nothing is rewound, and the
// numbering runs on as it does in a document with no steps at all.
#deck([
  == Static
  #figure(rect(width: 4mm, height: 2mm), caption: [one])
  #figure(rect(width: 4mm, height: 2mm), caption: [two])
])

#context {
  assert.eq(numbers-of(("one", "two")), (("one", 5), ("two", 6)))
}
