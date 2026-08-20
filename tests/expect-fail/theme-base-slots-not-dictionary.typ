// A complete base whose second reserved key is not a dictionary. The merge
// validates the base it is given rather than trusting it came from
// theme-tokens, exactly as it does for `extra`.
// EXPECT: theme-merge: base.slots must be a dictionary; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let base = { let b = theme-tokens(); b.insert("slots", 1); b }
#let _ = theme-merge(base, (:))
