// EXPECT: deck: aspect-ratio must be one of "16-9", "4-3"; got "21-9".
#import "../../src/render/deck.typ": deck
#let _ = deck([a], aspect-ratio: "21-9")
