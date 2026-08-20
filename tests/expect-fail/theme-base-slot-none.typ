// `none` clears a slot, which is a thing an override says. A base carrying it
// says nothing: a theme either carries a renderer or does not. Storing it would
// leave the key present and holding `none`, so a renderer that asks whether a
// slot is there would call one that is not.
// EXPECT: theme-merge: base.slots.render-header must be a function; got none. A
// EXPECT: theme carries a slot or it does not; none clears one in an override.
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let base = { let b = theme-tokens(); b.insert("slots", (render-header: none)); b }
#let _ = theme-merge(base, (:))
