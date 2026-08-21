// A section slide's title always came from a heading, so the section slot is
// always handed one and always has to place it. Declining loses the title and
// the body of the slide at once.
// EXPECT: deck: render-section-slide placed nothing on the slide titled [A
// EXPECT: section]. Place state.title, or return none only where the slide has
// EXPECT: no title.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let quiet = theme-tokens(
  slots: (render-section-slide: (info: none, tokens: none, state: none) => none),
)
#let _ = deck([= A section

== A slide

body], theme: quiet, slide-level: 2)
