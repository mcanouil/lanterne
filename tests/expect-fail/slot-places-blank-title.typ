// Declining is not the only way a slot can fail to place a title. Blank content
// leaves it exactly as lost: gone from the page, the outline and the bookmarks,
// with a label that lived on the heading existing nowhere in the document. `[]`
// is what an empty branch of a conditional yields, so this is the shape a theme
// reaches by accident rather than by intent.
// EXPECT: deck: render-header placed nothing on the slide titled [Titled].
// EXPECT: Place state.title, or return none only where the slide has no title.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let blank = theme-tokens(
  slots: (render-header: (info: none, tokens: none, state: none) => []),
)
#let _ = deck([== Titled

body], theme: blank)
