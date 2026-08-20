// A theme is validated by the one function that validates a theme, so a partial
// one fails here rather than where a missing token is read. The message names
// `theme`, which is the parameter the author wrote, rather than the `base` of
// the merge they never called.
// EXPECT: deck: theme is missing
#import "../../src/render/deck.typ": deck
#let _ = deck([a], theme: (bg: white))
