theme-tokens-wrong-type.typ
// EXPECT: theme-tokens: margin must be a length; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-tokens(margin: 1)
