// The relative half of the same rule, and the reason the rule is stricter than
// a comparison would be. A length carrying both an absolute and a relative part
// cannot be compared with `0pt` at all, so each part is judged on its own. That
// refuses `2cm - 1em`, which resolves positive at every plausible font size, so
// the message names the rule rather than claiming the value is negative.
// EXPECT: theme-tokens: header-height must be a non-negative length in both its
// EXPECT: absolute and relative parts; got 56.69pt + -1em.
#import "../../src/theme/tokens.typ": check-token
#check-token("header-height", 2cm - 1em, "theme-tokens")
