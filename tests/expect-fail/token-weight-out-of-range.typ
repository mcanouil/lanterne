token-weight-out-of-range.typ
// EXPECT: theme-tokens: weight-heading must be an integer from 100 to 900 or a
// EXPECT: weight name; got 950.
#import "../../src/theme/tokens.typ": check-token
#check-token("weight-heading", 950, "theme-tokens")
