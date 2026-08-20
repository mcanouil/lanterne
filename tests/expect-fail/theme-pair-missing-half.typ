// A dictionary carrying one half of a pair is a pair the author did not finish,
// not a token dictionary. Reading it as tokens would report `light` as an
// unknown token name, which names neither the mistake nor the fix.
// EXPECT: theme: a light and dark pair carries both halves, and this one
// EXPECT: carries only "light". Write (light: ..., dark: ...), or one token
// EXPECT: dictionary.
#import "../../src/theme/theme.typ": resolve-mode, theme-tokens
#let _ = resolve-mode((light: theme-tokens()), "light", "theme")
