// A theme is validated by the one function that validates a theme, so a partial
// one fails here rather than where a missing token is read.
// EXPECT: theme-merge: base is missing
#import "../../src/render/deck.typ": deck
#let _ = deck([a], theme: (bg: white))
