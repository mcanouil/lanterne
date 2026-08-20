// A pair carries its two halves and nothing else. A token written beside them
// would belong to neither half and would be read by nobody.
// EXPECT: deck: a light and dark pair carries no other key, and this one
// EXPECT: carries "bg". Write the token inside each half.
#import "../../src/render/deck.typ": deck
#import "../../src/theme/theme.typ": theme-tokens
#let _ = deck([a], theme: (light: theme-tokens(), dark: theme-tokens(), bg: white))
