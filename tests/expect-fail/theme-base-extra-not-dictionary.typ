// A complete base whose reserved key is not a dictionary. The merge validates
// the base it is given rather than trusting it came from theme-tokens.
// EXPECT: theme-merge: base.extra must be a dictionary; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let base = { let b = theme-tokens(); b.insert("extra", 1); b }
#let _ = theme-merge(base, (:))
