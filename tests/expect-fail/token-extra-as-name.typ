token-extra-as-name.typ
// `extra` is reserved rather than canonical, so it is reported as an unknown
// token name and the caller merging a theme handles it before reaching here.
// EXPECT: theme-tokens: token name must be one of "bg", "fg", "dim-opacity", "font-base", "font-heading", "size-base", "scale-ratio", "weight-heading", "leading", "margin"; got "extra".
#import "../../src/theme/tokens.typ": check-token
#check-token("extra", (:), "theme-tokens")
