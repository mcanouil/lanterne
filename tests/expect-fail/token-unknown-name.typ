token-unknown-name.typ
// A mistyped token name is an error, not a silent no-op. This is the guard
// that makes strict validation worth having.
// EXPECT: theme-tokens: token name must be one of "bg", "fg", "dim-opacity", "font-base", "font-heading", "size-base", "scale-ratio", "weight-heading", "leading", "margin"; got "bgg". A
// EXPECT: token of your own belongs in extra.
#import "../../src/theme/tokens.typ": check-token
#check-token("bgg", white, "theme-tokens")
