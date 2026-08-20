// The mode names which half of a pair to render, so an unrecognised one is
// refused rather than quietly taking the light half.
// EXPECT: deck: theme-mode must be one of "light", "dark"; got "auto".
#import "../../src/render/deck.typ": deck
#let _ = deck([a], theme-mode: "auto")
