// Numbering across the steps of a slide, asserted on the rendered document
// rather than on a record: a counter that re-increments is invisible to every
// structural assertion, because each step's body is the same content whatever
// number it renders with.
//
// The decks are called rather than shown, as in test-deck.typ, so several fit
// in one document and the queries below read all of them.

#import "/src/core/steps.typ": only, pause
#import "/src/render/deck.typ": deck

#set math.equation(numbering: "(1)")
#set heading(numbering: "1.")

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
  // The unnumbered deck at the end of this file contributes equations of its
  // own, which advance nothing, so only this slide's four are read here.
  assert.eq(equations.slice(0, 4), (1, 2, 1, 2))
  assert.eq(notes, (1, 2, 1, 2))
}

// A slide of one step is left exactly as it was: nothing is rewound, and the
// numbering runs on as it does in a document with no steps at all. The kind is
// its own so that the numbers are read against a counter no other deck in this
// file touches, and adding a figure above cannot move them.
#let plain(name) = figure(
  rect(width: 4mm, height: 2mm),
  caption: name,
  kind: "static",
  supplement: [Static],
)

#deck([
  == Static
  #plain([one])
  #plain([two])
])

#context {
  assert.eq(numbers-of(("one", "two")), (("one", 1), ("two", 2)))
}

// The heading counter is hierarchical, so it is stopped rather than rewound:
// a stepped slide must not advance it once per step, or every heading after it
// numbers too high.
#deck([
  == Stepped
  a #pause b

  == Counted <after-steps>
])

#context {
  // Six headings precede this point, one per slide in this file: Figures,
  // After, Equations and notes, Static, Stepped, and this one. The stepped
  // slide renders two pages and must still count once, so a seventh here
  // would mean a step page advanced the counter.
  assert.eq(counter(heading).at(query(<after-steps>).first().location()), (0, 6))
}

// A handout renders the final step alone, where the region is gone, and the
// counters are still advanced where it stood. The figure after it therefore
// carries the number it carries in the full deck, so a reference into the deck
// means the same in both. The kind is its own, so the number says what it is
// about rather than counting every figure written above it in this file.
#let kept-figure(name) = figure(
  rect(width: 4mm, height: 2mm),
  caption: name,
  kind: "handout",
  supplement: [Handout],
)

#deck(
  [
    == Handout
    #only("1", kept-figure([dropped]))
    #kept-figure([kept])
    #pause
    tail
  ],
  handout: true,
)

#context {
  assert.eq(numbers-of(("dropped", "kept")), (("kept", 2),))
}

// A removed region nested inside another is counted once, by the outer one,
// which is what keeps the arithmetic balanced: counting it twice would advance
// the counters further than the step ever did.
#let nested-figure(name) = figure(
  rect(width: 4mm, height: 2mm),
  caption: name,
  kind: "nested",
  supplement: [Nested],
)

#deck([
  == Nested
  #only("1", [#only("1", nested-figure([inner])) #nested-figure([middle])])
  #nested-figure([trailing])
  #pause
  tail
])

#context {
  assert.eq(
    numbers-of(("inner", "middle", "trailing")),
    (("inner", 1), ("middle", 2), ("trailing", 3), ("trailing", 3)),
  )
}

// The other side of the eligibility read, which every deck in this file has so
// far avoided: this file numbers equations at the top, while Typst's own
// default is none, and a figure can be turned off the same way. An element
// that does not number must not be rewound, or the counter goes backwards on
// every step and the next slide numbers below where it started.
#[
  #set math.equation(numbering: none)
  #set figure(numbering: none)

  #deck([
    == Unnumbered
    $ x = 1 $
    #figure(rect(width: 4mm, height: 2mm), caption: [quiet])
    #pause
    tail
  ])
]

#context {
  let unnumbered = query(figure).filter(it => it.caption.body.text == "quiet")
  // Two step pages, so two copies. Neither advances the counter, so both read
  // the same value, whatever the decks above left it at.
  assert.eq(unnumbered.len(), 2)
  let numbers = unnumbered.map(it => it.counter.at(it.location()).first())
  assert.eq(numbers.first(), numbers.last())

  // Nothing was rewound below where it started either, which is what a rewind
  // of an element that never advanced would produce.
  assert(query(math.equation).all(it => counter(math.equation).at(it.location()).first() >= 0))
  assert(numbers.all(value => value >= 0))
}
