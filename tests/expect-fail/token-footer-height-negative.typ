// The fourth name bound to the non-negative rule. See token-gutter-negative.typ
// for why an accepting case does not pin this.
// EXPECT: theme-tokens: footer-height must be a non-negative length in both its
// EXPECT: absolute and relative parts; got -28.35pt.
#import "../../src/theme/tokens.typ": check-token
#check-token("footer-height", -1cm, "theme-tokens")
