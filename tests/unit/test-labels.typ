// A label may be emitted once, and a slide body is emitted once per step.
//
// The assertions read the rendered document rather than content, for the
// reason test-walk-rebuild.typ gives: content equality ignores labels, so a
// pass that dropped every one of them would satisfy an equality assertion.
//
// A reference is what makes a duplicate label loud. Typst accepts a document
// carrying the same label twice and fails only where one is referenced, so the
// references below are the assertion, and this file failing to compile is the
// defect returning.

#import "/src/core/steps.typ": only, pause, uncover
#import "/src/render/deck.typ": deck

#set heading(numbering: "1.")

// Pages are read relative to the slide the label belongs to, so a deck added
// above cannot break an assertion about a deck below it. `opens` is the page
// the slide's first step renders on.
#let opens(title) = query(heading).find(it => it.body == title).location().page()
#let page-of(name) = query(name).first().location().page()

// A labelled title and a labelled figure behind a pause, on the same slide,
// with a reference to each.
#deck([
  == Titled <title>
  before
  #pause
  #figure(rect(width: 4mm, height: 2mm), caption: [c]) <paused>

  == Referring
  @title and @paused.
])

#context {
  // One of each, however many steps the slide renders.
  assert.eq(query(<title>).len(), 1)
  assert.eq(query(<paused>).len(), 1)
  // The title is shown on every step, so it keeps the first. The figure is
  // revealed on the second, so it keeps that one, and a reference lands where
  // the figure appears rather than on a page where it is hidden.
  assert.eq(page-of(<title>), opens([Titled]))
  assert.eq(page-of(<paused>), opens([Titled]) + 1)
}

// A region laid out on no early step keeps its label on the first step that
// shows it.
#deck([
  == Late
  #only("2-", [late <late>])
  #pause
  tail
])

#context {
  assert.eq(query(<late>).len(), 1)
  // The slide renders two steps, and the region is shown on the second.
  assert.eq(page-of(<late>), opens([Late]) + 1)
}

// A handout that renders no step at which the region is shown still has to put
// the label somewhere, or a reference into the deck fails to resolve. The
// fallback is the first step that lays the region out at all, which for an
// uncover is a step where it is hidden.
#deck(
  [
    == Handout
    #uncover("2-", [hidden here <fallback>])
    #pause
    tail
  ],
  handout: "1",
)

#context {
  assert.eq(query(<fallback>).len(), 1)
}

// Nesting composes: the inner region is visible from step 2 by its own range,
// but its parent removes it until step 3, so the label goes to step 3.
#deck([
  == Nested
  #only("3-", [outer #uncover("2-", [inner <nested>])])
  #pause
  #pause
  tail
])

#context {
  assert.eq(query(<nested>).len(), 1)
  // Three steps, and the label lands on the third, where the outer region
  // stops removing the inner one.
  assert.eq(page-of(<nested>), opens([Nested]) + 2)
}

// A labelled image inside a region that is dropped on some steps is not
// refused: the image is emitted on exactly one step, so no label duplicates
// and nothing has to be rebuilt on the steps that drop it.
#deck([
  == Only image
  #only("2", [#image("/tests/fixtures/quarto-deck-figure.svg", width: 5mm) <picture>])
  #pause
  tail
])

#context {
  assert.eq(query(<picture>).len(), 1)
  assert.eq(page-of(<picture>), opens([Only image]) + 1)
}

// A label on a group whose first child is a boundary goes to the first piece
// that carries something. Putting it on the empty piece the boundary opens
// would resolve a reference to a page showing nothing, or lose it altogether
// once the splitter drops that piece.
#deck([
  #[#set text(size: 9pt)
    == Wrapped
    body] <wrapper>
])

#context {
  assert.eq(query(<wrapper>).len(), 1)
}
