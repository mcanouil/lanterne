// EXPECT: theme: dark must be a token dictionary; got 1.
#import "../../src/theme/theme.typ": resolve-mode, theme-tokens
#let _ = resolve-mode((light: theme-tokens(), dark: 1), "light", "theme")
