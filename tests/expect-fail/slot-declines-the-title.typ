// A header slot is what moves the title out of the body, so a header that
// declines a page has nowhere left to put it. The title would be gone from the
// slide, from the outline and from the bookmarks, the heading counter would not
// step, and a label that lived on that heading would exist nowhere in the
// document, so a reference to the slide would fail naming neither the theme nor
// the slot.
// EXPECT: deck: render-header placed nothing on the slide titled [Titled]. Place
// EXPECT: state.title, or return none only where the slide has no title.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let shy = theme-tokens(
  slots: (render-header: (info: none, tokens: none, state: none) => none),
)
#let _ = deck([== Titled

body], theme: shy)
