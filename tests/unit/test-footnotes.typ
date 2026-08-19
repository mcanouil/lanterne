// A footnote inside a hidden region must not create its entry.
//
// `hide` reserves space and lays its content out, so a footnote behind a pause
// puts a real entry at the foot of the page and the separator rule appears a
// step before the note it belongs to. The assertions read the rendered
// document, since the entry is what a reader sees and no structural assertion
// over the slide body can tell whether one was made.

#import "/src/core/steps.typ": pause, uncover
#import "/src/render/deck.typ": deck

#let page-of(name) = query(heading).find(it => it.body == name).location().page()

// A query reads the whole document, so each assertion below is confined to the
// pages of the slide it is about.
#let notes-of(name, steps) = {
  let first = page-of(name)
  query(footnote).filter(it => (
    it.location().page() >= first and it.location().page() < first + steps
  ))
}

// The footnote is revealed on the second step, so the first step carries no
// entry at all.
#deck([
  == Behind a pause
  before
  #pause
  after#footnote[the note]
])

#context {
  let notes = notes-of([Behind a pause], 2)
  assert.eq(notes.len(), 1)
  assert.eq(notes.first().location().page(), page-of([Behind a pause]) + 1)
}

// The placeholder still advances the counter, so a footnote after the hidden
// one keeps the number it has on the step that shows both.
#deck([
  == Two notes
  first#footnote[one]
  #pause
  second#footnote[two]
])

#context {
  let numbers = notes-of([Two notes], 2).map(it => counter(footnote).at(it.location()).first())
  // Three entries: the first note on each of the two steps, and the second note
  // on the step that reveals it. The numbers are read against each other rather
  // than as absolutes, since a deck above this one numbers notes of its own.
  assert.eq(numbers.len(), 3)
  assert.eq(numbers.at(0), numbers.at(1))
  assert.eq(numbers.at(2), numbers.at(1) + 1)
}

// A hidden footnote reserves the space its mark would take, so the text around
// it does not move when the note is revealed. This pins the Typst behaviour the
// placeholder rests on: the mark is a superscript of the numbering, and a
// hidden one measures the same.
#context {
  assert.eq(measure(footnote[x]).width, measure(super[1]).width)
  assert.eq(measure(hide(super[1])).width, measure(super[1]).width)
  // A two digit number is wider, which is why the placeholder carries the
  // number the footnote will take rather than a fixed digit.
  assert(measure(super[10]).width > measure(super[1]).width)
}

// An uncover region behaves as a pause does, and a note inside a region that is
// shown from the first step is untouched.
#deck([
  == Uncovered
  #uncover("2-", [late#footnote[deferred]])
  #pause
  tail
])

#context {
  let notes = notes-of([Uncovered], 2)
  assert.eq(notes.len(), 1)
  assert.eq(notes.first().location().page(), page-of([Uncovered]) + 1)
}
