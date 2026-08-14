token-font-bare-nameless.typ
// The bare form is validated by the same rule as a list entry.
// EXPECT: theme-tokens: font-base must be a font family name or coverage-scoped entry, or a non-empty array of them; got (covers:
// EXPECT: "latin-in-cjk").
#import "../../src/theme/tokens.typ": check-token
#check-token("font-base", (covers: "latin-in-cjk"), "theme-tokens")
