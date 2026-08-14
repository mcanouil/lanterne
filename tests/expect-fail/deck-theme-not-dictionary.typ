// EXPECT: deck: theme must be a token dictionary or none; got "dark".
#import "../../src/render/deck.typ": deck
#let _ = deck([a], theme: "dark")
