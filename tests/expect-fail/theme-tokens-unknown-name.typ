theme-tokens-unknown-name.typ
// The scope names the function the author called, not the private helper both
// public functions route through.
// EXPECT: theme-tokens: token name must be one of "bg", "fg", "dim-opacity", "font-base", "font-heading", "size-base", "scale-ratio", "weight-heading", "leading", "margin"; got "bgg". A
// EXPECT: token of your own belongs in extra.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-tokens(bgg: white)
