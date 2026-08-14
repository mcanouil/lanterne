token-wrong-type.typ
// A colour token given a string that reads like a colour.
// EXPECT: theme-tokens: bg must be a colour; got "red".
#import "../../src/theme/tokens.typ": check-token
#check-token("bg", "red", "theme-tokens")
