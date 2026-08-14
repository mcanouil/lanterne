token-size-base-em.typ
// The base size is the one length that cannot be relative, since an em value
// there would be relative to itself.
// EXPECT: theme-tokens: size-base must be a positive absolute length; got 2em.
#import "../../src/theme/tokens.typ": check-token
#check-token("size-base", 2em, "theme-tokens")
