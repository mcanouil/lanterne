token-font-empty.typ
// An empty fallback list selects nothing at all rather than falling back.
// EXPECT: theme-tokens: font-base must be a font family name or coverage-scoped entry, or a non-empty array of them; got ().
#import "../../src/theme/tokens.typ": check-token
#check-token("font-base", (), "theme-tokens")
