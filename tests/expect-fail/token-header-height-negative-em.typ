// The relative half of the same rule. A length carrying both an absolute and a
// relative part cannot be compared with `0pt` at all, so the rule reads the two
// components separately and this reaches the package's own message rather than
// Typst's `cannot compare` error.
// EXPECT: theme-tokens: header-height must be a non-negative length; got 56.69pt +
// EXPECT: -1em.
#import "../../src/theme/tokens.typ": check-token
#check-token("header-height", 2cm - 1em, "theme-tokens")
