// The smallest complete deck: a section, two slides, and the rules of
// specification section 4.1 at work.
//
// Compiled by tools/check.sh alongside the unit tests, so an example that stops
// building fails the suite.

#import "../lib.typ": *

#show: deck.with(
  theme: theme-tokens(
    bg: rgb("#fbfbfd"),
    fg: rgb("#1c1c22"),
    margin: 3cm,
  ),
  aspect-ratio: "16-9",
  slide-level: 2,
  info: (
    title: [Hello, lanterne],
    author: "Mickaël Canouil",
  ),
)

= Getting started

== What a deck is <what-a-deck-is>

A level 2 heading opens a slide and becomes its title.
A level 1 heading opens a section slide, which is the page before this one.

=== Headings below the slide level

A heading deeper than the slide level is ordinary content, so this line and the
one above it sit on the slide the level 2 heading opened.

== Slides written out in full

#slide-options(smaller: true)

This slide asked to be set smaller, which the deck reads from the option marker
written after its heading.

Content can also be broken by hand:

#pagebreak()

A page break at body level opens a slide of its own, with no title.

#slide(title: [A slide of one's own])[
  An explicit slide is complete in itself, and is not merged with whatever
  surrounds it.
]

== Cross references

A labelled heading is a destination, so #link(<what-a-deck-is>)[this link] jumps
back to the slide that carries the label.

Typst refuses `@what-a-deck-is` on a heading that is not numbered, so a
reference by name waits for the numbering rules rather than being faked here.
