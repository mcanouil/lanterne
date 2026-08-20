// A slot's arity cannot be checked, since Typst exposes nothing of a closure's
// parameters, but what it returns can be. A slot returning a value would place
// it on the page and the deck would build.
// EXPECT: deck: render-header result must be content; got 1.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let broken = theme-tokens(slots: (render-header: (info: none, tokens: none, state: none) => 1))
#let _ = deck([== A

body], theme: broken)
