// A deck built with every step primitive: pause, an open ended uncover, focus,
// only and a step-aware slide.
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
    title: [Stepping through a deck],
    author: "Mickaël Canouil",
  ),
)

= Revealing content

== Revealed in turn

The first line is on screen from the start.

#pause

A pause opens a step boundary, so this line waits for the second step.

#pause

A third step reveals this line, and nothing above it moves when it appears.

== An open ended uncover

#uncover("2-")[
  This region stays hidden through the first step and stays visible from the
  second step onward, however many steps the slide ends up with.
]

Ordinary content sits alongside it, visible from the start, and the hidden
region still reserves its space, so nothing on the slide reflows when it
appears.

== Two regions, one in focus

#focus("1", [The first region is full strength on step one.])

#focus("2", [The second region takes its turn on step two.])

Each region dims rather than disappears when it is not in focus, which is
what lets a reader keep their place. Typst 0.15 has no content opacity, so
`focus` dims by setting the text fill: an image, an explicit fill and a
stroke inside a focused region do not dim.

== Shown for one step only

#only("2", [This line renders on step two alone: absent before it and absent after.])

The rest of the slide is visible on every step, and the step the line
disappears into reserves no space at all, so the slide reflows around it.

== A slide that counts its own steps

#slide-options(steps: 4)

#context-slide((index, total) => [Step #index of #total.])

A `context-slide` callback cannot be counted, because what it returns does not
exist when the step count is computed, so this slide raises its own count with
`slide-options(steps: 4)` rather than leaving it at the one step the rest of
the body would otherwise advertise.
