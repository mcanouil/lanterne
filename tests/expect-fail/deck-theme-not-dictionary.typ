// EXPECT: deck: theme must be a token dictionary, a light and dark pair, or
// EXPECT: none; got "dark".
#import "../../src/render/deck.typ": deck
#let _ = deck([a], theme: "dark")
