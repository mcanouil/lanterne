// The base half of the type guard, naming the reserved key of the base rather
// than the one an override would have written.
// EXPECT: theme-merge: base.slots.render-header must be a function or none; got 1.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let base = { let b = theme-tokens(); b.insert("slots", (render-header: 1)); b }
#let _ = theme-merge(base, (:))
