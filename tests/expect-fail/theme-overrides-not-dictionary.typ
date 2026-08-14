// EXPECT: theme-merge: overrides must be a dictionary of token values; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-merge(theme-tokens(), 1)
