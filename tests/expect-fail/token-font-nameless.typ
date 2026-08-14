token-font-nameless.typ
// A coverage-scoped entry without a family name selects nothing.
// EXPECT: theme-tokens: font-base must be a font family name, or a non-empty array of names and coverage-scoped entries; got ((covers:
// EXPECT: "latin-in-cjk"),).
#import "../../src/theme/tokens.typ": check-token
#check-token("font-base", ((covers: "latin-in-cjk"),), "theme-tokens")
