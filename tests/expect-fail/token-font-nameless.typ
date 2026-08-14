token-font-nameless.typ
// A coverage-scoped entry without a family name selects nothing, whether it
// is written bare or inside a fallback list.
// EXPECT: theme-tokens: font-base must be a font family name or coverage-scoped entry, or a non-empty array of them; got ((covers:
// EXPECT: "latin-in-cjk"),).
#import "../../src/theme/tokens.typ": check-token
#check-token("font-base", ((covers: "latin-in-cjk"),), "theme-tokens")
