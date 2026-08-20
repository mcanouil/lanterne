// `slots` is the second reserved key, and like `extra` it is not a token. It
// is validated, but against the fixed set of renderer names rather than
// against a token rule, so it is reported here as an unknown token name.
// EXPECT: theme-tokens: token name must be one of "bg", "fg", "accent", "accent-fg",
// EXPECT: "muted", "border", "dim-opacity", "font-base", "font-heading", "size-base",
// EXPECT: "scale-ratio", "weight-heading", "leading", "margin", "gutter",
// EXPECT: "header-height", "footer-height", "stroke-width"; got "slots". A token of
// EXPECT: your own belongs in extra.
#import "../../src/theme/tokens.typ": check-token
#check-token("slots", (:), "theme-tokens")
