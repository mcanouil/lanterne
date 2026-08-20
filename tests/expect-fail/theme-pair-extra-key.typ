// A pair carries its two halves and nothing else. A token written beside them
// would belong to neither half and would be read by nobody.
// EXPECT: theme: a light and dark pair carries no other key, and this one
// EXPECT: carries "bg". Write the token inside each half.
#import "../../src/theme/theme.typ": resolve-mode, theme-tokens
#let _ = resolve-mode((light: theme-tokens(), dark: theme-tokens(), bg: white), "light", "theme")
