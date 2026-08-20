// A title passed to `slide(...)` is never in the body, so it renders only where
// a slot places it. A header that declines loses it as completely as it loses a
// heading, and with less to show for it: nothing was taken out, so nothing is
// left behind either.
// EXPECT: deck: render-header placed nothing on the slide titled [Explicit].
// EXPECT: Place state.title, or return none only where the slide has no title.
#import "../../src/core/slides.typ": slide
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let shy = theme-tokens(
  slots: (render-header: (info: none, tokens: none, state: none) => none),
)
#let _ = deck([#slide(title: [Explicit])[body]], theme: shy)
