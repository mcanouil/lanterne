// The same rejection reached through the other public function, which must
// name itself rather than its neighbour.
// EXPECT: theme-merge: token name must be one of "bg", "fg", "accent", "accent-fg",
// EXPECT: "muted", "border", "dim-opacity", "font-base", "font-heading", "size-base",
// EXPECT: "scale-ratio", "weight-heading", "leading", "margin", "gutter",
// EXPECT: "header-height", "footer-height", "stroke-width"; got "bgg". A token of your
// EXPECT: own belongs in extra.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-merge(theme-tokens(), (bgg: white))
