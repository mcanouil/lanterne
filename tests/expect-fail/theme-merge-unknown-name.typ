theme-merge-unknown-name.typ
// The same rejection reached through the other public function, which must
// name itself rather than its neighbour.
// EXPECT: theme-merge: token name must be one of "bg", "fg", "dim-opacity", "font-base", "font-heading", "size-base", "scale-ratio", "weight-heading", "leading", "margin"; got "bgg". A
// EXPECT: token of your own belongs in extra.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-merge(theme-tokens(), (bgg: white))
