// A half is named with its parent, as every other nested key in a theme is, so
// `dark` reads as the half of a theme rather than as a parameter of `deck`.
// EXPECT: deck: theme.dark must be a token dictionary; got 1.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let _ = deck([a], theme: (light: theme-tokens(), dark: 1))
