// EXPECT: deck: info must be a dictionary of document metadata; got "A talk".
#import "../../src/render/deck.typ": deck
#let _ = deck([a], info: "A talk")
