// EXPECT: theme-tokens: slots must be a dictionary; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let _ = theme-tokens(slots: 1)
