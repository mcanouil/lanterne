// A dictionary carrying one half of a pair is a pair the author did not finish,
// not a token dictionary. Reading it as tokens would report `light` as an
// unknown token name, which names neither the mistake nor the fix.
//
// Driven through `deck`, which is what an author writes, so the scope in the
// message is the one a user sees and the wiring that carries it is proven.
// EXPECT: deck: a light and dark pair carries both halves, and this one carries
// EXPECT: only "light". Write (light: ..., dark: ...), or one token dictionary.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let _ = deck([a], theme: (light: theme-tokens()))
