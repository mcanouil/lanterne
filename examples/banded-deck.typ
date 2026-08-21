// The banded theme, which composes a page rather than dressing one.
//
// The title sits in a coloured band, the deck's own title runs along the foot
// above a rule, and a section slide gives the band up for a page of its own.
// Nothing here sets a slot: the theme carries all three.
//
// Compiled by tools/check.sh alongside the unit tests, and every page is a
// visual golden, so this is where a composed page is finally pinned by
// something that can see it.

#import "../lib.typ": *

#show: deck.with(
  theme: theme-banded(accent: rgb("#1f5fa9"), bg: rgb("#fbfbfd"), fg: rgb("#1c1c22")),
  aspect-ratio: "16-9",
  slide-level: 2,
  info: (title: [Banded], author: "Mickaël Canouil"),
)

= Composing a page

== A title in the band

The theme takes this slide's title out of the body and places it in the header
region. It is still the heading written above: a rule of your own restyles it, a
reference to it resolves, and the outline lists it once.

== A slide that steps

The band and the footer are drawn again on every step, and the title is numbered
once for the slide rather than once for the page.

#pause

The second step carries the same chrome and the same title.

== A slide with a table

#table(
  columns: (auto, 1fr),
  [Region], [Filled by],
  [Header], [`render-header`],
  [Footer], [`render-footer`],
)

#pagebreak()

An untitled slide has nothing for the band to hold, so the theme declines the
region and the body keeps the space.
