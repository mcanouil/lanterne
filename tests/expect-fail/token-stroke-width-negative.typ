// A rule of negative thickness describes nothing. Zero is accepted, since a
// theme suppresses a rule by giving it no width.
// EXPECT: theme-tokens: stroke-width must be a non-negative length in both its
// EXPECT: absolute and relative parts; got -1pt.
#import "../../src/theme/tokens.typ": check-token
#check-token("stroke-width", -1pt, "theme-tokens")
