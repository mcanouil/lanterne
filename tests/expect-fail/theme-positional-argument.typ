theme-positional-argument.typ
// A positional argument carries no token name to validate against, so it is
// rejected rather than ignored.
// EXPECT: theme-tokens: takes named arguments only; got (luma(100%),). Write
// EXPECT: theme-tokens(bg: white).
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-tokens(white)
