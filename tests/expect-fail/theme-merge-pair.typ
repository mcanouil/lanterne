// A pair reaching `theme-merge` is the obvious next thing an author tries after
// writing one. Without a guard it fails as a token dictionary missing all
// eighteen names, which describes neither the mistake nor the fix: a token
// belongs to a half, so a merge is per half.
// EXPECT: theme-merge: base is a light and dark pair, carrying "light", "dark".
// EXPECT: Merge into each half, as theme-merge(pair.light, ...).
#import "../../src/theme/theme.typ": theme-merge, theme-tokens
#let pair = (light: theme-tokens(), dark: theme-tokens())
#let _ = theme-merge(pair, (bg: red))
