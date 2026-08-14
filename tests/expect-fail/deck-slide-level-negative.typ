// The split validates the deck's slide level and reports it under the name the
// author called, since they have no `slides` call to go and look at.
// EXPECT: deck: slide-level must be a non-negative integer; got -1.
#import "../../src/render/deck.typ": deck
#let _ = deck([a], slide-level: -1)
