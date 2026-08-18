// EXPECT: document did not converge within five attempts
//
// The gate under test is in tools/check.sh: a compile that exits zero and
// writes to stderr is a failure. This deck exercises it with the shape that
// found the rule, namely a snapshot of a counter taken on one step of a slide
// and put back on the next, which feeds each slide's value into the next and
// takes more layout runs than Typst allows.
//
// It is written against the public surface rather than against a package
// internal, so it keeps warning whatever the step engine does next.
#import "/lib.typ": *

#let snapshot = state("snapshot", ())
#let freeze = context-slide((index, total) => if index == 1 {
  context snapshot.update(counter(figure.where(kind: image)).get())
} else {
  context counter(figure.where(kind: image)).update(snapshot.get())
})

#show: deck.with(slide-level: 2)

== One
#freeze
#figure(rect(width: 8mm, height: 4mm), caption: [a])
#pause
tail

== Two
#freeze
#figure(rect(width: 8mm, height: 4mm), caption: [b])
#pause
tail

== Three
#freeze
#figure(rect(width: 8mm, height: 4mm), caption: [c])
#pause
tail
