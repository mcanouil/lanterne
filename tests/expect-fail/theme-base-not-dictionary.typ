// EXPECT: theme-merge: base must be a token dictionary; got 1.
#import "../../src/theme/theme.typ": theme-merge
#let _ = theme-merge(1, (:))
