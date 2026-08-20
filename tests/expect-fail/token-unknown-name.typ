// A mistyped token name is an error, not a silent no-op. This is the guard
// that makes strict validation worth having.
// EXPECT: theme-tokens: token name must be one of "bg", "fg", "accent", "accent-fg",
// EXPECT: "muted", "border", "dim-opacity", "font-base", "font-heading", "size-base",
// EXPECT: "scale-ratio", "weight-heading", "leading", "margin", "gutter",
// EXPECT: "header-height", "footer-height", "stroke-width"; got "bgg". A token of your
// EXPECT: own belongs in extra.
#import "../../src/theme/tokens.typ": check-token
#check-token("bgg", white, "theme-tokens")
