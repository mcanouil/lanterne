// One rejecting case per name bound to the non-negative rule, rather than one
// for the rule. An accepting case cannot tell the two apart: `0pt` and `0.6cm`
// satisfy the permissive `a length` rule as well, so a _SPEC entry wired to the
// wrong `ok` would leave this suite green.
// EXPECT: theme-tokens: gutter must be a non-negative length in both its
// EXPECT: absolute and relative parts; got -5.67pt.
#import "../../src/theme/tokens.typ": check-token
#check-token("gutter", -2mm, "theme-tokens")
