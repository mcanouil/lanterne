theme-extra-not-dictionary.typ
// EXPECT: theme-tokens: extra must be a dictionary; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-tokens(extra: 1)
