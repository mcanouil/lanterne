// A slot is called by the renderer, so content in its place would be a theme
// that builds and then fails at the moment a page is composed.
// EXPECT: theme-tokens: slots.render-header must be a function or none; got [].
#import "../../src/theme/theme.typ": theme-tokens
#let _ = theme-tokens(slots: (render-header: []))
