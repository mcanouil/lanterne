// A footnote inside a hidden region must not create its entry.
//
// `hide` reserves space and lays its content out, so a footnote behind a pause
// puts a real entry at the foot of the page and the separator rule appears a
// step before the note it belongs to. The assertions read the rendered
// document, since the entry is what a reader sees and no structural assertion
// over the slide body can tell whether one was made.

#import "/src/core/steps.typ": focus, only, pause, uncover
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
  // The number in play, rather than a fixed digit: notes written above this
  // point decide what the next one is, and a two digit mark is wider.
  let next = numbering(footnote.numbering, counter(footnote).get().first() + 1)
  assert.eq(measure(footnote[x]).width, measure(super(next)).width)
  assert.eq(measure(hide(super(next))).width, measure(super(next)).width)
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

// A dimmed region is laid out and visible, so its footnote keeps its entry.
// Replacing it would take the note off the page while the text that refers to
// it is still legible.
#deck([
  == Dimmed
  #focus("2", [emphasised#footnote[still here]])
  #pause
  tail
])

#context {
  assert.eq(notes-of([Dimmed], 2).len(), 2)
}

// A hidden region inside another advances the counter once, not once per level,
// so a note after them keeps its number.
#deck([
  == Nested hidden
  #uncover("2-", [outer #uncover("2-", [inner#footnote[deep]])])
  #pause
  after#footnote[following]
])

#context {
  let numbers = notes-of([Nested hidden], 2).map(it => counter(footnote).at(it.location()).first())
  // Step 1 shows neither note. Step 2 shows both, in order, one apart.
  assert.eq(numbers.len(), 2)
  assert.eq(numbers.at(1), numbers.at(0) + 1)
}

// A footnote written as a reference to an existing note makes no entry and
// advances nothing, so it is left alone rather than given a placeholder that
// would push the numbers along.
#deck([
  == Referenced
  first#footnote[the note] <note>
  #pause
  again#footnote(<note>)
  last#footnote[another]
])

#context {
  // A query reports footnote elements, and a reference is one, so the entries
  // are the ones whose body is not a label.
  let numbers = notes-of([Referenced], 2)
    .filter(it => type(it.body) != label)
    .map(it => counter(footnote).at(it.location()).first())
  // One entry on the first step, two on the step that reveals the rest, and the
  // second numbered one past the first: the reference consumed no number, which
  // it would have done had the placeholder been given to it.
  assert.eq(numbers.len(), 3)
  assert.eq(numbers.at(0), numbers.at(1))
  assert.eq(numbers.at(2), numbers.at(1) + 1)
}

// A footnote that sets its own numbering reserves the width of its own scheme
// rather than the style's, so the line does not reflow when the note appears.
#deck([
  == Own scheme
  #uncover("2-", [starred#footnote(numbering: "*")[symbol]])
  #pause
  tail
])

#context {
  assert.eq(notes-of([Own scheme], 2).len(), 1)
}

// A handout of the final step alone still carries no early entry, since there
// is no earlier step to carry one.
#deck(
  [
    == Handout notes
    #uncover("2-", [late#footnote[deferred]])
    #pause
    tail
  ],
  handout: true,
)

#context {
  assert.eq(notes-of([Handout notes], 1).len(), 1)
}
